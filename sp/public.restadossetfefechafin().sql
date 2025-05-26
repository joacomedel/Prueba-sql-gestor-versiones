CREATE OR REPLACE FUNCTION public.restadossetfefechafin()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE

BEGIN
UPDATE restados SET refechafin = current_date
 WHERE restados.nroreintegro = NEW.nroreintegro AND restados.anio = NEW.anio
 AND restados.idcentroregional = NEW.idcentroregional
 AND nullvalue(restados.refechafin);
 RETURN NEW;
END;
$function$
