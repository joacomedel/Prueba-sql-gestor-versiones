CREATE OR REPLACE FUNCTION public.to_ascii_2(ptexto text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare

   vtexto text;

BEGIN
SELECT INTO vtexto to_ascii(convert_to(ptexto, 'latin1'), 'latin1');

return vtexto;
END;
$function$
