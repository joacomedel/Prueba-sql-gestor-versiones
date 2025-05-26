CREATE OR REPLACE FUNCTION public.darfechafinos(date)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
DECLARE
	diastresmeses integer;
	dianuevo float8;
	dia float8;
	fecha date;
BEGIN
	diastresmeses = 88;
	
	while NOT ( SELECT EXTRACT (day FROM date (date $1 + integer diastresmeses)) = SELECT EXTRACT (day FROM date $1)) LOOP
	 diatresmeses = diatresmeses + 1;
	END LOOP;
	
return '2006-01-01';	
END;
$function$
