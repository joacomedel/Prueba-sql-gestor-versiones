CREATE OR REPLACE FUNCTION public.far_ingresarordenventa()
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
        rrespuesta record;
        elafiliado RECORD; 
        telarticulo RECORD;
        rcob far_plancoberturainfomedicamentoafiliado_2;
BEGIN

              SELECT INTO elafiliado * FROM persona as p JOIN tfar_ordenventa AS tfov ON (p.nrodoc=tfov.nrocliente
                       AND p.tipodoc=tfov.barra) 
                     --cambie 17/12/14 KR  LEFT JOIN far_afiliado as fa USING (nrodoc, tipodoc) WHERE nullvalue(fa.nrodoc);
                -- KR 18-8-15 debe verificar que la persona no este en far_afiliado y no lo estaba haciendo por el comentario anterior                     
                       LEFT JOIN far_afiliado as fa USING (nrodoc, tipodoc) 
                       LEFT JOIN cliente as c ON (tfov.nrocliente=c.nrocliente AND tfov.barra=c.barra)
                              WHERE nullvalue(c.nrocliente) or nullvalue(fa.nrodoc);
              IF FOUND THEN /*El afiliado esta en persona pero no se cargo en far_afiliado*/
                  SELECT INTO telarticulo *, CASE WHEN nullvalue(fosvc.idobrasocial) THEN 9 else fosvc.idobrasocial END AS laobrasocial
                     FROM tfar_ordenventa NATURAL JOIN tfar_ordenventaitem JOIN tfar_ordenventaitemimportes USING(idordenventaitem)
                          LEFT JOIN far_obrasocialvalorescaja   as fosvc USING  (idvalorescaja);
                        CREATE TEMP TABLE tfar_articulo (mnroregistro VARCHAR,idarticulo BIGINT,idcentroarticulo BIGINT,convale
                        BOOLEAN,idafiliado VARCHAR,idobrasocial INTEGER,cantvendida INTEGER,idvalidacion INTEGER) WITH OIDS;
                        INSERT INTO tfar_articulo(idarticulo,idcentroarticulo, idafiliado,idobrasocial,idvalidacion)	   
                        VALUES(telarticulo.idarticulo,telarticulo.idcentroarticulo,telarticulo.idafiliado,telarticulo.laobrasocial,
                        telarticulo.idvalidacion);
                       SELECT INTO rcob * FROM far_traerinfocoberturas();
              /*busco el cliente del afiliado que ingrese*/  
              SELECT INTO elafiliado * FROM persona NATURAL JOIN far_afiliado as fa 
                WHERE fa.nrodoc=elafiliado.nrocliente and fa.tipodoc=elafiliado.barra;
              UPDATE tfar_ordenventa SET nrocliente = elafiliado.nrocliente, barra=elafiliado.barra; 

              END IF;



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
	     IF (rordenventa.idordenventatipo = 2 OR rordenventa.idordenventatipo = 4 ) THEN

		INSERT INTO far_ordenventareceta(idordenventa,idcentroordenventa,nromatricula,malcance,mespecialidad,ovrfechauso,nrorecetario,centro,idprestador)
		VALUES(codordenventa,centro(),rordenventa.nromatricula,rordenventa.malcance,rordenventa.mespecialidad,rordenventa.ovfechauso,rordenventa.ovnroreceta,rordenventa.centro,rordenventa.idprestador);

	     END IF;

              -- Ingreso cada uno de los item de la venta de ese tipo (perfumeria,medicamento)
              OPEN cordenventaitem FOR SELECT * FROM  tfar_ordenventaitem;
              FETCH cordenventaitem into rordenventaitem;
              WHILE  found LOOP
		--modifique para guardar los precios por unidad
                     SELECT INTO rarticulo * FROM far_articulo WHERE idarticulo = rordenventaitem.idarticulo AND idcentroarticulo = rordenventaitem.idcentroarticulo;
                     IF nullvalue(rordenventaitem.oviidiva) THEN 
                                voviidiva = 2;
                     ELSE 
                                voviidiva = rordenventaitem.oviidiva;
                     END IF; 
                     IF (rordenventa.idordenventatipo<>3 and rordenventa.idordenventatipo<>5 
                              and rordenventa.idordenventatipo<>4 and rordenventa.idordenventatipo<>6
                            and rordenventa.idordenventatipo<>7 ) THEN
                        IF (rarticulo.idrubro=4) THEN --es un medicamento
                              UPDATE  far_ordenventa SET idordenventatipo=2 WHERE idordenventa =codordenventa  AND idcentroordenventa=centro();
                        ELSE 
                              UPDATE  far_ordenventa SET idordenventatipo=1 WHERE idordenventa = codordenventa AND idcentroordenventa=centro();
                        END IF;
                     END IF; 
                     INSERT INTO far_ordenventaitem(idordenventa,idcentroordenventa,idarticulo,idcentroarticulo,ovidescripcion,ovicantidad,idcentroordenventaitem,
                     oviprecioventa,ovidescuento,ovipreciolista,oviimpdescuento,oviimporteiva,oviidiva)
                     VALUES(codordenventa,centro(),rordenventaitem.idarticulo,rordenventaitem.idcentroarticulo,concat(rarticulo.acodigobarra ,'-' , rordenventaitem.ovidescripcion ),
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

      IF (rordenventa.idordenventatipo<>3 and rordenventa.idordenventatipo<>5  and rordenventa.idordenventatipo<>6)  THEN --no es presupuesto, ni vale, ni regalo
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

-- Malapi 04-04-2014: Para que verifique si tiene que fraccionar un articulo padre.
  SELECT INTO rrespuesta * FROM far_verificaventaarticulosfraccionados(codordenventa,centro());

--KR 29-07-19 Verifico que no sea nulo el afiliado en la tabla far_ordenventaitemimportes
/*  UPDATE far_ordenventaitemimportes SET oviitipodoc=T.tipodoc, oviinrodoc=T.nrodoc, oviiidobrasocial=T.idobrasocial 
    FROM (SELECT idordenventaitemimporte, idcentroordenventaitemimporte, tipodoc, nrodoc, idobrasocial
          FROM far_ordenventa NATURAL JOIN far_ordenventaitem NATURAL JOIN far_ordenventaitemimportes JOIN far_afiliado ON (oviiidafiliadocobertura=far_afiliado.idafiliado)
          WHERE idordenventa = codordenventa AND idcentroordenventa =centro()  AND nullvalue(oviinrodoc)
         ) AS T
  WHERE far_ordenventaitemimportes.idordenventaitemimporte= T.idordenventaitemimporte AND far_ordenventaitemimportes.idcentroordenventaitemimporte=T.idcentroordenventaitemimporte;
*/

return concat(codordenventa,'|',centro());
END;
$function$
