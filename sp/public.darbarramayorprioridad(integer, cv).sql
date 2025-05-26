CREATE OR REPLACE FUNCTION public.darbarramayorprioridad(integer, character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	tipodocumento alias for $1;
	nrodocumento alias for $2;
	todasbarras CURSOR FOR SELECT * FROM barras WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento AND prioridad = (SELECT min(prioridad) FROM barras WHERE nrodoc = nrodocumento AND tipodoc = tipodocumento);
	elem RECORD;
	resultado integer;
BEGIN
resultado = 0;

OPEN todasbarras;
FETCH todasbarras INTO elem;
WHILE  found LOOP
	if elem.barra > resultado
		then
			resultado = elem.barra;
	end if;
fetch todasbarras into elem;
END LOOP;
CLOSE todasbarras;

return resultado;
END;
$function$
