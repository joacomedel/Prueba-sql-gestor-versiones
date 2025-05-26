CREATE OR REPLACE FUNCTION public.insertarestadonuevoafiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	aux boolean;
BEGIN

SELECT INTO aux * FROM insertarestadonuevapers(1,NEW.tipodoc,NEW.nrodoc,NEW.idestado);
return NEW;
END;
$function$
