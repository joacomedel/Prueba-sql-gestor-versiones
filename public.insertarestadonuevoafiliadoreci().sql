CREATE OR REPLACE FUNCTION public.insertarestadonuevoafiliadoreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	aux boolean;
BEGIN

SELECT INTO aux * FROM insertarestadonuevapers(3,NEW.tipodoc,NEW.nrodoc,NEW.idestado);
return NEW;
END;
$function$
