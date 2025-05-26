CREATE OR REPLACE FUNCTION public.asientogenericoreclibrofact_crear_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE

 xidasiento numeric;
BEGIN
--	SELECT INTO xidasiento asientogenericoreclibrofact_crear(NEW.numeroregistro*10000+NEW.anio);
	perform asientogenericoreclibrofact_crear(NEW.numeroregistro*10000+NEW.anio);
        
	return NEW;
END;
$function$
