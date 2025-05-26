CREATE OR REPLACE FUNCTION public.asientogenericocobranza_crear_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
BEGIN
	-- pidoperacion formato: ''100011125501'	
	perform asientogenericocobranza_crear(concat(NEW.idrecibo,'|',NEW.centro));
	return NEW;
END;
$function$
