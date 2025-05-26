CREATE OR REPLACE FUNCTION public.actualizarlafechadefinosbenef()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
aux boolean;


BEGIN
--SELECT INTO pers * FROM persona WHERE nrodoc= NEW.nrodoc and tipodoc= NEW.tipodoc;
	SELECT INTO aux * FROM actualizarlafechadefinosbenefsosunc(NEW.nrodoc,NEW.tipodoc);
return NEW;
	
END;
$function$
