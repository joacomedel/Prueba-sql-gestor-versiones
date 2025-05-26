CREATE OR REPLACE FUNCTION public.far_anularordenventa()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rordenventa record;
        cordenventaitem  refcursor;
        rordenventaitem record;
        codordenventa bigint;
        nroinforme bigint;
        rinformeordventa record;
        resp boolean;
        cordenventa 
            CURSOR FOR 
                SELECT * 
                FROM tfar_ordenventa 
                NATURAL JOIN far_ordenventa
                NATURAL JOIN far_ordenventaestado
                WHERE
                    nullvalue(ovefechafin)
                    AND idordenventaestadotipo=1
                LIMIT 1;


      

BEGIN

              
OPEN cordenventa;
FETCH cordenventa into rordenventa;
WHILE  FOUND LOOP
    IF FOUND THEN 
              -- Cambio el estado actual de la orden de venta
              /*UPDATE  far_ordenventaestado SET ovefechafin = NOW()
              WHERE nullvalue(ovefechafin)
                   AND idordenventa = rordenventa.idordenventa
                   AND idcentroordenventa =rordenventa.idcentroordenventa;*/
              -- Ingreso el nuevo estado de la venta
--              INSERT INTO far_ordenventaestado(ovefechaini,idordenventaestadotipo,idordenventa, idcentroordenventa)
--              VALUES(NOW(),2, rordenventa.idordenventa,rordenventa.idcentroordenventa);

        --GK 23-09-2022 control de estado 

        PERFORM far_cambiarestadoordenventa(rordenventa.idordenventa,rordenventa.idcentroordenventa,2);

        -- Realizo el movimiento de stock correspondiente a la anulacion venta
        CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
             
        INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)
            VALUES(
             concat(' Anulacion Comprobante Orden Venta ',rordenventa.idordenventa,'|',rordenventa.idcentroordenventa),2);
        
        SELECT INTO resp far_movimientostocknuevo('far_ordenventa',concat(rordenventa.idordenventa,'|',rordenventa.idcentroordenventa));

        --KR 17-04 vuelvo a dejar el articulo en estado para ser vendido nuevamente y updateo a nulo la orden con la que estaba vinculado al ser vendido. 
        PERFORM  far_modificararticulotrazable(NULL, NULL,2, T.idarticulotraza, T.idcentroarticulotraza) FROM (
             
        SELECT idordenventaitem, idcentroordenventaitem, idarticulotraza, idcentroarticulotraza
        FROM far_articulotrazabilidad JOIN far_ordenventaitem USING(idordenventaitem ,idcentroordenventaitem)
        WHERE idordenventa=  rordenventa.idordenventa and idcentroordenventa=rordenventa.idcentroordenventa) AS T;


    END IF;

FETCH cordenventa into rordenventa;
END LOOP;
CLOSE cordenventa;

  

return 'true';
END;
$function$
