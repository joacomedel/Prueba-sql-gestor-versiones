CREATE OR REPLACE FUNCTION public.festadossetfefechafin()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
 
BEGIN
  UPDATE festados SET fefechafin = current_date 
  WHERE nullvalue(fefechafin) AND festados.nroregistro = NEW.nroregistro AND festados.anio = NEW.anio;


  RETURN NEW;
END;
$function$
