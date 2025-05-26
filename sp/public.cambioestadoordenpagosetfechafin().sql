CREATE OR REPLACE FUNCTION public.cambioestadoordenpagosetfechafin()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
  
BEGIN
	UPDATE cambioestadoordenpago 
		SET ceopfechafin = CURRENT_DATE
	WHERE nroordenpago = NEW.nroordenpago AND idcentroordenpago = NEW.idcentroordenpago AND nullvalue(ceopfechafin);
RETURN NEW;
END;
$function$
