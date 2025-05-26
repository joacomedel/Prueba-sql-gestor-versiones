CREATE OR REPLACE FUNCTION public.far_actualizarstockordenventa(bigint, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       ccomprobanteitem refcursor;
       rcomprobanteitem record;
       codmovimientostock bigint;

       idcomprobante varchar;
       elidordenventa  bigint;
       elidcentroordenventa integer;
       resp boolean;
       elestado record;
       signo integer;
       fechavencimiento date;
       verifica record;
BEGIN
     codmovimientostock =$1;
     idcomprobante = $2;
     fechavencimiento = null;
     signo = null;
     -- recupero la clave de la orden de venta
     SELECT INTO elidordenventa split_part(idcomprobante, '|',1);
     SELECT INTO elidcentroordenventa split_part(idcomprobante, '|',2);


     -- Corroboro el estado de la orden de venta para determinar si se trata de un incremento o decremento de stock
     SELECT INTO elestado * FROM far_ordenventaestado
     WHERE idcentroordenventa = elidcentroordenventa
           and  idordenventa =elidordenventa
           and nullvalue(ovefechafin);
     IF (elestado.idordenventaestadotipo = 1) THEN -- 1 	Generada
             signo = -1;
     END IF;
     IF (elestado.idordenventaestadotipo = 2)  THEN  --- 2 Cancelada
              signo = 1;
     END IF;
      IF (elestado.idordenventaestadotipo = 3)  THEN  --- 3 Facturada
            --MaLaPi 13-06-2018 Si la orden esta facturada solo tengo que generar movimiento de stock si es que aun no se genero para esa orden un movimiento
            SELECT INTO verifica * FROM far_ordenventaitem
                              NATURAL JOIN far_movimientostockitemordenventa
                              WHERE idordenventa = elidordenventa
                                    AND idcentroordenventa = elidcentroordenventa
                              LIMIT 1;
       IF NOT FOUND THEN
          signo = -1;
       END IF;
              
     END IF;

     IF nullvalue(signo) THEN
        --Si el signo no es diferente de null, no se que operacion se debe hacer por lo que no hago nada
        
     ELSE
     /* Esta temporal va a contener las claves de los lotes que fueron afectados con el movimiento*/
     CREATE TEMP TABLE movimientostockitemtmp(idmovimientostockitem bigint);
     OPEN ccomprobanteitem FOR  SELECT *
                          FROM far_ordenventaitem
                          WHERE idordenventa = elidordenventa
                                and idcentroordenventa = elidcentroordenventa;

     FETCH ccomprobanteitem into rcomprobanteitem;
     WHILE  found LOOP

                   SELECT INTO resp  far_articulomoverstock
                   (rcomprobanteitem.idarticulo,rcomprobanteitem.idcentroarticulo,rcomprobanteitem.ovicantidad,signo,fechavencimiento,codmovimientostock);
                   INSERT INTO far_movimientostockitemordenventa(idmovimientostockitem,idordenventaitem,idcentroordenventaitem,msiovsigno)
                          SELECT idmovimientostockitem, rcomprobanteitem.idordenventaitem, rcomprobanteitem.idcentroordenventaitem,signo
                          FROM movimientostockitemtmp;
                   DELETE FROM movimientostockitemtmp;
                   fetch ccomprobanteitem into rcomprobanteitem;
      END LOOP;

      close ccomprobanteitem;
      END IF; --IF nullvalue(signo) THEN
return 'true';
END;
$function$
