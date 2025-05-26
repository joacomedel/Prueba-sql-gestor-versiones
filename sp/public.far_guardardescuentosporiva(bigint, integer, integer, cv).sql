CREATE OR REPLACE FUNCTION public.far_guardardescuentosporiva(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       ptipocomprobante integer;
       pnrosucursal integer;
       pnrofactura bigint;
       ptipofactura varchar ;
       pagodescuento DOUBLE PRECISION;
       pagototal DOUBLE PRECISION;
       pagoInteres DOUBLE PRECISION;
       intereses DOUBLE PRECISION;
       pagodto DOUBLE PRECISION;
       cfar_ordenventaimporte refcursor;
       cfar_ordenventaimporteInteres refcursor;
       cfar_pagointereses refcursor;
       undescuento record;
       unPlan record;
       unPago record;
       importedescuento DOUBLE PRECISION;
       importeInteres DOUBLE PRECISION;
       factorfinanciero DOUBLE PRECISION;
       arancel DOUBLE PRECISION;
       idivaaux bigint = 2; 
       pagoTotalAux DOUBLE PRECISION;
       importeInteresAux DOUBLE PRECISION;

     
BEGIN

     pnrofactura  =$1;
     pnrosucursal =$2;
     ptipocomprobante =$3;
     ptipofactura  =$4;
     pagoTotalAux = 0;

      ----- Aca se calcula el importe pagado por el afiliado teniendo en cuenta los descuentos * cada forma de pago
     SELECT INTO pagodescuento  SUM( monto- montointeres)
     FROM tempfacturaventacupon   JOIN valorescaja USING (idvalorescaja);

    SELECT INTO intereses  SUM(montointeres)
     FROM tempfacturaventacupon   JOIN valorescaja USING (idvalorescaja);

     SELECT INTO pagodto  SUM( montodto)
     FROM tempfacturaventacupon   JOIN valorescaja USING (idvalorescaja);
     
     SELECT INTO pagototal  SUM( monto +montodto- montointeres)
     FROM tempfacturaventacupon   JOIN valorescaja USING (idvalorescaja);
   
    ----- Aca se calcula el importe TOTAL que paga el afiliado agrupado por tipo de iva
 IF pagototal <> 0 THEN 
     IF ptipofactura ='FA' OR ptipofactura ='NC' THEN  
--BelenA 10-12-24 agrego que se fije si es NC tambien para las de tarjeta de farmacia
            IF pagodto <> 0 THEN
                        OPEN cfar_ordenventaimporte FOR
                        SELECT SUM(far_ordenventaitemimportes.oviimonto ) as importetotalafil,oviidiva,concat('Desc. IVA ',descripcion) as descripciondescuento
                        FROM far_ordenventaitemimportes
                        NATURAL JOIN far_ordenventaitem
                        JOIN temporden ON (idordenventa=nroorden AND idcentroordenventa=centro)
                        JOIN tipoiva ON(idiva=oviidiva)
                        WHERE  far_ordenventaitemimportes.idvalorescaja = 0  AND  idcentroordenventaitem = temporden.centro 
                        GROUP BY oviidiva,descripcion;
            END IF;

            IF intereses <> 0 THEN
                    -- Si el idvalorescaja=0 es un importe a cargo del afiliado donde el valor caja se define en la facturacion
                    OPEN cfar_ordenventaimporteInteres FOR
                          SELECT  SUM(far_ordenventaitemimportes.oviimonto ) as importetotalafil,oviidiva,concat('Intereses IVA ',descripcion  ) as descripcion,ptarancel,ptfactorfinanciero,tipoiva.porcentaje as iva,oviifpcantcuotas as cuotas
                          FROM far_ordenventaitemimportes
                          NATURAL JOIN far_ordenventaitem
                          JOIN temporden ON (idordenventa=nroorden AND idcentroordenventa=centro)
                          JOIN tempoviiformapago as tfp ON (tfp.idordenventa=temporden.nroorden)
                          JOIN planes_tarjeta ON (planes_tarjeta.idplantarjeta = tfp.oviifpidplantarjeta)
                          JOIN tipoiva ON(idiva=oviidiva)
                          WHERE idcentroordenventaitem = temporden.centro AND ptcuotas > 1 AND far_ordenventaitemimportes.idvalorescaja = 0
                          GROUP BY far_ordenventaitem.oviidiva, tipoiva.descripcion,ptfactorfinanciero,ptarancel,iva,cuotas;

                          

            END IF;

      ELSE 
                    --MaLaPi 21-02-2018 Cambio para que tome el importe que viene desde la interfaz. Se cambia porque cuando se emite una NC de una factura que tiene mas de una orden y que en esas ordenes hay productos con diferentes coberturas esta formula no da el valor real que abona el afiliado, pues se asume que el afiliado paga lo mismo por todos los articulos iguales y esto no es correcto. 
                      OPEN cfar_ordenventaimporte FOR
                         SELECT /*SUM((far_ordenventaitemimportes.oviimonto/ovicantidad ) *cantidad ) as importetotalafil*/ sum(importe) as importetotalafil,
                                oviidiva,concat('Desc. IVA ',tipoiva.descripcion) as descripciondescuento
                         FROM far_ordenventaitemimportes
                         NATURAL JOIN far_ordenventaitem
                         JOIN (
                              SELECT tipofactura, tipocomprobante, nrosucursal, nrofactura, iditem,
                                     SUM( ovcantdevueltas )as cantdevueltas ,MIN( idcentroordenventaitem) as idcentroordenventaitem,
                                     MIN(idordenventaitem) as idordenventaitem  
                                     FROM far_ordenventaitemitemfacturaventa
                                     group by  tipofactura, tipocomprobante, nrosucursal, nrofactura, iditem
                         )as T USING (idordenventaitem,idcentroordenventaitem)
                         NATURAL JOIN temitemfacturaventa  NATURAL JOIN tempfacturaventa
                         JOIN tipoiva ON(tipoiva.idiva=oviidiva)
                         WHERE  idvalorescaja = 0
                         group by oviidiva,tipoiva.descripcion;
     --- Se debe insertar en item facturaventa el importe del descueNto
     END IF;

      IF pagodto<>0 THEN
       FETCH cfar_ordenventaimporte into undescuento ;
       WHILE FOUND LOOP
                 importedescuento = round(CAST ((undescuento.importetotalafil-((pagodescuento / pagototal)*undescuento.importetotalafil)) AS numeric),2);

                  IF importedescuento<>0 THEN
                               INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
                               VALUES(ptipocomprobante,pnrosucursal,ptipofactura,pnrofactura,
                               50840,1,importedescuento*-1,undescuento.descripciondescuento ,undescuento.oviidiva);
                          
                  END IF;
                  FETCH cfar_ordenventaimporte into undescuento ;
       END LOOP;
     END IF;

     -- German : En caso de que la orden tenga cuotas se calculan a continuacion 
     IF intereses<>0 THEN

        FETCH cfar_ordenventaimporteInteres into unPlan ;
        -- itero por los diferentes planes dentro de la Factura
        WHILE FOUND LOOP
                  --- Cambio 21/04/2020 German control de cantidad de cuotas para el caso de que una orden tenga dos planes de cuotas 
                  FOR unPago IN  SELECT SUM( monto -montodto- montointeres) as montosininteres,cuotas
                   FROM tempfacturaventacupon   JOIN valorescaja USING (idvalorescaja)
                   WHERE cuotas>1
                   GROUP BY cuotas LOOP
                   -- Verifico que el monto corresponde al plan controlando el numero de cuotas
                      IF unPago.cuotas = unPlan.cuotas THEN
                          pagointeres = unPago.montosininteres;

                          -- Calculo el pago total en base a las cuotas 
                          SELECT  INTO pagoTotalAux SUM(far_ordenventaitemimportes.oviimonto ) as importetotalafil
                          FROM far_ordenventaitemimportes
                          NATURAL JOIN far_ordenventaitem
                          JOIN temporden ON (idordenventa=nroorden AND idcentroordenventa=centro)
                          JOIN tempoviiformapago as tfp ON (tfp.idordenventa=temporden.nroorden)
                          JOIN planes_tarjeta ON (planes_tarjeta.idplantarjeta = tfp.oviifpidplantarjeta)
                          WHERE idcentroordenventaitem = temporden.centro AND ptcuotas = unPlan.cuotas AND far_ordenventaitemimportes.idvalorescaja = 0;

 
                      END IF;

                  END LOOP;
                  ---------------------------

                  importeInteresAux = round(CAST ((unPlan.importetotalafil-((pagointeres / pagoTotalAux)*unPlan.importetotalafil)) AS numeric),2);
                  importeInteresAux = round(CAST (((importeInteresAux - unPlan.importetotalafil)*-1) AS numeric),2);

                  factorfinanciero = round(CAST ((importeInteresAux*unPlan.ptfactorfinanciero) AS numeric),2);
                  arancel = round(CAST ((factorfinanciero*(unPlan.ptarancel/100)) AS numeric),2);
                  importeInteres = round(CAST ((factorfinanciero+arancel-importeInteresAux) AS numeric),2);

                  importeInteres = round(CAST ((importeInteres / (1 + unPlan.iva) )AS numeric),2);

                  IF importeInteres<>0 THEN
                               INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
                               VALUES(ptipocomprobante,pnrosucursal,ptipofactura,pnrofactura,
                               50841,1,importeInteres,unPlan.descripcion ,unPlan.oviidiva);
                          
                  END IF;
                  FETCH cfar_ordenventaimporteInteres into unPlan ;
       END LOOP;
    END IF;


  END IF;



return 'true';
END;
$function$
