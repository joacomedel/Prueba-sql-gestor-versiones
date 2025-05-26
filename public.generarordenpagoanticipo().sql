CREATE OR REPLACE FUNCTION public.generarordenpagoanticipo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Genera una orden para pagar un conjunto de anticipos, realizando el cambio de estados para los
mismos.*/

DECLARE
	anticipos refcursor;
	unanticipo RECORD;
	resultado boolean;
BEGIN
/*Llamo para que se inserte la Orden de Pago*/

SELECT INTO resultado * FROM generarordenpago();
if resultado THEN
   /*Modifico el estado de los anticipos y su vinculacion a la Orden de pago*/
   OPEN anticipos FOR SELECT * FROM tempanticipo;
   FETCH anticipos INTO unanticipo;
   WHILE  found LOOP
   UPDATE anticipo  SET nroordenpago = unanticipo.nroordenpago
                      ,tipoformapago =unanticipo.tipoformapago
                      WHERE anticipo.nroanticipo = unanticipo.nroanticipo AND anticipo.anio =  unanticipo.anio;
    /*El anticipo se coloca en estado 3 - Liquidado*/
   INSERT INTO aestados (fechacambio,nroanticipo,anio,tipoestadoanticipo,observacion)
   VALUES (CURRENT_DATE,unanticipo.nroanticipo,unanticipo.anio,3,concat('Al ser generada la orden',unanticipo.nroanticipo));
   FETCH anticipos INTO unanticipo;
   END LOOP;
   CLOSE anticipos;
   resultado = 'true';
END IF;
RETURN resultado;
END;
$function$
