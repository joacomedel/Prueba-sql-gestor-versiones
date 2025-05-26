CREATE OR REPLACE FUNCTION public.precede(tablauno text, tablados text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	tablasrelacionadas refcursor;
	tablarel record;
	encontradarel boolean;
	aux record;
begin
encontradarel:=false;
if tablados = '' then
	return 'true';
else
open tablasrelacionadas for
			select relname as nombre from pg_class join (select distinct confrelid 				from pg_class join pg_constraint on (pg_class.oid = conrelid) where 				relname = tablados and confrelid <> 0) as ids on(confrelid = oid);
		fetch tablasrelacionadas into tablarel;
		while found and not encontradarel loop
			encontradarel:= (tablauno = tablarel.nombre);
			fetch tablasrelacionadas into tablarel;
		end loop;
close tablasrelacionadas;
return encontradarel;
end if;
end;
$function$
