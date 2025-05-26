CREATE OR REPLACE FUNCTION public.marcarultimopase()
 RETURNS trigger
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$BEGIN
  /* New function body */

    RAISE NOTICE 'pidultimo - id  OLD.idpase %', OLD.idpase; 
   UPDATE paseinfodocumento SET pidultimo = FALSE WHERE idpase = OLD.idpase AND idcentropase = OLD.idcentropase;
   RAISE NOTICE 'pidultimo - id  NEW.idpase %', NEW.idpase; 
   UPDATE paseinfodocumento SET pidultimo = TRUE WHERE idpase = NEW.idpase AND idcentropase = NEW.idcentropase;
   

  RETURN NEW;
END;
$function$
