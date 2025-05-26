CREATE OR REPLACE FUNCTION public.datoscarnets()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	barras CURSOR FOR SELECT * FROM tmp_Barras;
	elem RECORD;

BEGIN

OPEN barras;
FETCH barras INTO elem;
WHILE  found LOOP
     SELECT INTO resultado * FROM datosCarnetsOrdenados(elem.barra);

FETCH barras INTO elem;   
END LOOP;
CLOSE barras;
return 'true';
END;
$function$
