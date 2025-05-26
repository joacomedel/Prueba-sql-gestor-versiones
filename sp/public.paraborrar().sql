CREATE OR REPLACE FUNCTION public.paraborrar()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	baja CURSOR FOR SELECT   table_schema,table_name
FROM information_schema.tables
WHERE (table_name ilike 'far_%' or table_name ilike 'adesfa_%' or
table_name ilike 'liquidador%')

AND table_schema ilike 'public'
 	and table_name <>'farmacias' and table_name <>'farmtipounid'
 	and table_name <>'farmtipoventa'
ORDER BY table_schema,table_name;


	elem RECORD;
	rtablas RECORD;
	resultado boolean;
	
BEGIN


OPEN baja;
FETCH baja INTO elem;


WHILE  found LOOP

SELECT INTO rtablas * FROM tablasasincronizar where nombre=elem.table_name;
if not found then

 	select into  resultado * from agregarsincronizable(elem.table_name);

end if;

fetch baja into elem;
END LOOP;
CLOSE baja;
return 'true';

END;
$function$
