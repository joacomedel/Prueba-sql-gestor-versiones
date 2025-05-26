CREATE OR REPLACE FUNCTION public.expendio_asentarfacturaventa_2_deuda_ctacte(pidrecibo integer, pcentro integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare

respuesta boolean;


BEGIN

UPDATE importesorden SET idformapagotipos = 3 
WHERE idformapagotipos = 2 AND (nroorden,centro) 
 IN (SELECT nroorden,centro FROM ordenrecibo 
                            WHERE idrecibo = pidrecibo 
                            AND centro = pcentro);

UPDATE importesrecibo  SET idformapagotipos = 3 
WHERE idrecibo = pidrecibo AND centro = pcentro AND idformapagotipos = 2;
                            
SELECT INTO respuesta * FROM asentarconsumoctactev2(pidrecibo,pcentro,null);

RETURN respuesta;

END;
$function$
