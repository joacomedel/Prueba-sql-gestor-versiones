CREATE OR REPLACE FUNCTION public.getmax(character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
campo alias for $1;
ret RECORD;
rid BIGINT;
secuencia RECORD;
BEGIN
execute concat('SELECT MAX(',campo,') as nro FROM secuencias;') into ret;
rid = ret.nro + 1;
execute concat('UPDATE secuencias SET ',campo,' = ',rid,';');
RETURN rid;
END;
$function$
