CREATE OR REPLACE FUNCTION public.far_anularordenventasintocarstock(pidordenventa bigint, pidcentroordenventa integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
        rordenventa record;
        cordenventaitem  refcursor;
        rordenventaitem record;
        codordenventa bigint;
        nroinforme bigint;
        rinformeordventa record;
        resp boolean;
      

BEGIN
              SELECT INTO rordenventa *  FROM far_ordenventa 
                 WHERE idordenventa = pidordenventa AND idcentroordenventa = pidcentroordenventa;

              -- Cambio el estado actual de la orden de venta
              UPDATE  far_ordenventaestado SET ovefechafin = NOW()
              WHERE nullvalue(ovefechafin)
                   AND idordenventa = rordenventa.idordenventa
                   AND idcentroordenventa =rordenventa.idcentroordenventa;
              -- Ingreso el nuevo estado de la venta
              INSERT INTO far_ordenventaestado  (ovefechaini,idordenventaestadotipo,idordenventa, idcentroordenventa)
              VALUES(NOW(),2, rordenventa.idordenventa,rordenventa.idcentroordenventa);
              

             -- Realizo el movimiento de stock correspondiente a la anulacion venta
           --  CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
            -- INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)VALUES(
            -- concat(' Anulacion Comprobante Orden Venta ',rordenventa.idordenventa,'|',rordenventa.idcentroordenventa),2);
            -- SELECT INTO resp far_movimientostocknuevo('far_ordenventa',concat(rordenventa.idordenventa,'|',rordenventa.idcentroordenventa));
return 'true';
END;
$function$
