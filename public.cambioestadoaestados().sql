CREATE OR REPLACE FUNCTION public.cambioestadoaestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  
BEGIN
  UPDATE aestados SET aefechafin= CURRENT_DATE 
  WHERE nroanticipo = NEW.nroanticipo 
  	AND anio = NEW.anio
    AND idcentroregional = NEW.idcentroregional;
   
  RETURN NEW;

END;
$function$
