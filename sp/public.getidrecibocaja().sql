CREATE OR REPLACE FUNCTION public.getidrecibocaja()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
/* Funcion que devuelve el nro de recibo, tener en cuenta que el que se encuentra
en la tabla actualmente ya se ha utilizado.*/
DECLARE
	
    ridrecibo BIGINT;
	secuencia RECORD;
BEGIN

SELECT INTO secuencia MAX(idrecibocaja) as nrorecibo FROM secuencias;

ridrecibo = secuencia.nrorecibo + 1;
UPDATE secuencias SET idrecibocaja = ridrecibo;
RETURN ridrecibo;
END;
$function$
