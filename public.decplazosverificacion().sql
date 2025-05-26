CREATE OR REPLACE FUNCTION public.decplazosverificacion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	veri CURSOR FOR SELECT * FROM verificacion WHERE rango >0;
	elem RECORD;
BEGIN

OPEN veri;
FETCH veri into elem;
WHILE  found LOOP
	UPDATE verificacion SET rango = elem.rango-1 WHERE codigo = elem.codigo AND nrodoc = elem.nrodoc;
fetch veri into elem;
END LOOP;
close veri;
return 'true';
END;
$function$
