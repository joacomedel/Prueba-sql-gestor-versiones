CREATE OR REPLACE FUNCTION public.getmaxconcentro(character varying, integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
campo alias for $1;
centro alias for $2;
ret RECORD;
rid BIGINT;
secuencia RECORD;
BEGIN
execute concat('SELECT MAX(',campo,') as nro FROM secuencias WHERE secuencias.centro = ' , to_char(centro,'99') , ';') into ret;
rid = ret.nro + 1;
execute concat('UPDATE secuencias SET ',campo,' = ',rid,' WHERE secuencias.centro = ' , to_char(centro,'99') , ';');

RETURN rid;
END;
$function$
