CREATE OR REPLACE FUNCTION public.far_ingresarordenventa_2()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
        rordenventa record;
        cordenventaitem  refcursor;
        cordenventaitemimportes  refcursor;
        rordenventaitem record;
        rordenventaitemimportes record;
        rarticulo record;
        rvendedor record;
        codordenventa bigint;
        nroinforme bigint;
        resp boolean;
        voviidiva DOUBLE PRECISION;
        elvendedor integer;

BEGIN

 

              SELECT INTO rordenventa *  FROM tfar_ordenventa;
              -- Ingreso los datos de la venta de un tipo (perfumeria,medicamento)

              -- verifico que exista el vendedor
              SELECT INTO rvendedor * FROM far_vendedor WHERE idvendedor=rordenventa.idvendedor;
              IF FOUND THEN
                     elvendedor=rordenventa.idvendedor;
              ELSE elvendedor=12; 
              END IF; 
              INSERT INTO far_ordenventa(idafiliado,ovfechaemision,idordenventatipo,idcentroordenventa,idvendedor,ovobservacion,nrocliente,barra,ovnombrecliente,idvalidacion)
              VALUES(rordenventa.idafiliado,now(),rordenventa.idordenventatipo,centro(),elvendedor,rordenventa.ovobservacion,rordenventa.nrocliente,rordenventa.barra,rordenventa.ovnombrecliente,rordenventa.idvalidacion);
              codordenventa = currval('public.far_ordenventa_idordenventa_seq');
               
	     
               -- Vinculo la orden con el recetario
	      IF (rordenventa.ovnroreceta <> '') THEN

		INSERT INTO far_ordenventareceta(idordenventa,idcentroordenventa,nromatricula,malcance,mespecialidad,ovrfechauso,nrorecetario,centro)
		VALUES(codordenventa,centro(),rordenventa.nromatricula,rordenventa.malcance,rordenventa.mespecialidad,rordenventa.ovfechauso,rordenventa.ovnroreceta,rordenventa.centro);

	      END IF;

              -- Ingreso cada uno de los item de la venta de ese tipo (perfumeria,medicamento)
              OPEN cordenventaitem FOR SELECT * FROM  tfar_ordenventaitem;
              FETCH cordenventaitem into rordenventaitem;
              WHILE  found LOOP
		--modifique para guardar los precios por unidad
                     SELECT INTO rarticulo * FROM far_articulo WHERE idarticulo = rordenventaitem.idarticulo;
                     IF nullvalue(rordenventaitem.oviidiva) THEN 
                                voviidiva = 2;
                     ELSE 
                                voviidiva = rordenventaitem.oviidiva;
                     END IF; 
                     IF (rordenventa.idordenventatipo<>3) THEN
                        IF (rarticulo.idrubro=4) THEN --es un medicamento
                              UPDATE  far_ordenventa SET idordenventatipo=2 WHERE idordenventa =codordenventa  AND idcentroordenventa=centro();
                        ELSE 
                              UPDATE  far_ordenventa SET idordenventatipo=1 WHERE idordenventa = codordenventa AND idcentroordenventa=centro();
                        END IF;
                     END IF; 
                     INSERT INTO far_ordenventaitem(idordenventa,idcentroordenventa,idarticulo,idcentroarticulo,ovidescripcion,ovicantidad,idcentroordenventaitem,
                     oviprecioventa,ovidescuento,ovipreciolista,oviimpdescuento,oviimporteiva,oviidiva)
                     VALUES(codordenventa,centro(),rordenventaitem.idarticulo,rordenventaitem.idcentroarticulo,concat( rarticulo.acodigobarra , '-' ,rordenventaitem.ovidescripcion),
                     rordenventaitem.ovicantidad,centro(),
(1+rordenventaitem.ovialicuotaiva)*rordenventaitem.ovipreciolista*(1-rordenventaitem.ovidescuento),
rordenventaitem.ovidescuento,
rordenventaitem.ovipreciolista,
(1+rordenventaitem.ovialicuotaiva)*rordenventaitem.ovipreciolista*rordenventaitem.ovidescuento,
rordenventaitem.ovialicuotaiva*rordenventaitem.ovipreciolista,voviidiva);

OPEN cordenventaitemimportes FOR SELECT * FROM  tfar_ordenventaitemimportes WHERE idordenventaitem = rordenventaitem.idordenventaitem;

              FETCH cordenventaitemimportes into rordenventaitemimportes;
              WHILE  found LOOP
                       
 INSERT INTO far_ordenventaitemimportes(idordenventaitem,idcentroordenventaitem,idvalorescaja,oviimonto,oviiporcentajecobertura,oviiautorizacion,oviiidafiliadocobertura)
VALUES(CURRVAL('far_ordenventaitem_idordenventaitem_seq'),centro(),rordenventaitemimportes.idvalorescaja,rordenventaitemimportes.oviimonto,rordenventaitemimportes.oviicob,rordenventaitemimportes.oviiautorizacion,rordenventaitemimportes.idafiliadocobertura);

              FETCH cordenventaitemimportes into rordenventaitemimportes;
              END LOOP;
              close cordenventaitemimportes;


              FETCH cordenventaitem into rordenventaitem;
              END LOOP;

      close cordenventaitem;

      IF (rordenventa.idordenventatipo<>3)  THEN --no es presupuesto
      -- Realizo el movimiento de stock correspondiente a la venta
          --El cambio de estado se tiene que hacer antes de llamar al cambio de stock
          --DEJO LA ORDEN pendiente de facturacion 
         INSERT INTO far_ordenventaestado(ovefechaini,ovefechafin,idordenventaestadotipo,idordenventa,idcentroordenventa)
              VALUES(now(),null,1,codordenventa,centro());

         CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
         INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)VALUES(concat('Nueva Venta  Comprobante OV:  ',codordenventa,'|',centro()) ,2);
         SELECT INTO resp far_movimientostocknuevo('far_ordenventa',concat(codordenventa,'|',centro()));
        
      ELSE ---ES un presupuesto, lo dejo en estado no requiere facturacion
              INSERT INTO far_ordenventaestado(ovefechaini,ovefechafin,idordenventaestadotipo,idordenventa,idcentroordenventa)
              VALUES(now(),null,17,codordenventa,centro());
      END IF;
return concat(codordenventa,'|',centro());
END;
$function$
