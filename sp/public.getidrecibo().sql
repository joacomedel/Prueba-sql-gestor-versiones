CREATE OR REPLACE FUNCTION public.getidrecibo()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$/* Funcion que devuelve el nro de recibo, tener en cuenta que el que se encuentra
en la tabla actualmente ya se ha utilizado.*/
DECLARE
	
    ridrecibo BIGINT;
	secuencia RECORD;
BEGIN
LOCK TABLE secuencias IN SHARE MODE;

SELECT INTO secuencia MAX(idrecibo) as nrorecibo FROM secuencias;

ridrecibo = secuencia.nrorecibo + 1;
UPDATE secuencias SET idrecibo = ridrecibo;
RETURN ridrecibo;
END;
$function$
