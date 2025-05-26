CREATE OR REPLACE FUNCTION public.limpiarsincro()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	tablas cursor for select * from tablasasincronizar order by orden;
	tabla record;
begin
	open tablas;
	fetch tablas into tabla;
	while FOUND loop
		execute concat('DELETE FROM sincro.',tabla.nombre,';');
		fetch tablas into tabla;
	end loop;
	close tablas;
return 'true';
end;
$function$
