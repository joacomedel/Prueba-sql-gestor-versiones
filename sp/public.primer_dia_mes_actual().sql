CREATE OR REPLACE FUNCTION public.primer_dia_mes_actual()
 RETURNS timestamp without time zone
 LANGUAGE sql
AS $function$
/* New function body */

SELECT DATE_TRUNC('month', CURRENT_DATE)::timestamp
$function$
