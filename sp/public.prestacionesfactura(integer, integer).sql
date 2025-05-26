CREATE OR REPLACE FUNCTION public.prestacionesfactura(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
lasprestaciones refcursor;
losdebitos refcursor;

--REGISTRO
unaprestacion RECORD;
undebito RECORD;
regep RECORD;
regedfp RECORD;

--VARIABLES
importetotalapagar DOUBLE PRECISION;

BEGIN
importetotalapagar=0;
DELETE FROM facturaprestaciones  WHERE nroregistro= $1 AND anio=$2;
DELETE FROM debitofacturaprestador  WHERE nroregistro= $1 AND anio=$2;

  OPEN lasprestaciones FOR SELECT * FROM tprestaciones WHERE  nroregistro =$1  and anio=$2;
  FETCH lasprestaciones INTO unaprestacion;
   WHILE  found LOOP
             
             SELECT INTO regep * FROM facturaprestaciones 
                              WHERE nroregistro= unaprestacion.nroregistro AND anio=unaprestacion.anio AND fidtipoprestacion = unaprestacion.fidtipoprestacion;
             IF FOUND THEN 
                     UPDATE facturaprestaciones set importe = regep.importe + unaprestacion.importe
						 , debito = regep.debito + unaprestacion.debito
				 WHERE anio =unaprestacion.anio AND nroregistro =unaprestacion.nroregistro 
				 AND fidtipoprestacion = unaprestacion.fidtipoprestacion;
             ELSE 
                    INSERT INTO facturaprestaciones (anio,nroregistro,fidtipoprestacion,importe,debito)  VALUES(unaprestacion.anio,unaprestacion.nroregistro ,unaprestacion.fidtipoprestacion,unaprestacion.importe,unaprestacion.debito);
             
             END IF;

             FETCH lasprestaciones INTO unaprestacion;
    END LOOP;
    CLOSE lasprestaciones;

OPEN losdebitos FOR SELECT * FROM tdebitos WHERE  nroregistro =$1  and anio=$2;
FETCH losdebitos INTO undebito;
   WHILE  found LOOP
             
             SELECT INTO regedfp * FROM debitofacturaprestador 
                              WHERE nroregistro= undebito.nroregistro AND anio=undebito.anio AND fidtipoprestacion = undebito.fidtipoprestacion 
                              AND idmotivodebitofacturacion= undebito.idmotivodebitofacturacion;

             IF FOUND THEN 
                     UPDATE debitofacturaprestador set importe = regedfp.importe + undebito.importe
						 
				 WHERE nroregistro= undebito.nroregistro AND anio=undebito.anio AND fidtipoprestacion = undebito.fidtipoprestacion 
                              AND idmotivodebitofacturacion= undebito.idmotivodebitofacturacion;
             ELSE 
                    INSERT INTO debitofacturaprestador (anio,nroregistro,fidtipoprestacion,importe,observacion,idmotivodebitofacturacion)  VALUES(undebito.anio,undebito.nroregistro ,undebito.fidtipoprestacion,undebito.importe, undebito.observacion,undebito.idmotivodebitofacturacion);
             
             END IF;

             FETCH losdebitos INTO undebito;
    END LOOP;
    CLOSE losdebitos;

   SELECT INTO importetotalapagar SUM (importe - (CASE WHEN nullvalue(debito) THEN 0 ELSE debito END)) FROM facturaprestaciones  WHERE nroregistro =$1 AND anio = $2;
   UPDATE factura set fimportepagar = importetotalapagar WHERE nroregistro =$1 AND anio = $2;

return true;

END;

$function$
