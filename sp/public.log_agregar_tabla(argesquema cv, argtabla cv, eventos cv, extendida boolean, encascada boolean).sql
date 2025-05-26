CREATE OR REPLACE FUNCTION public.log_agregar_tabla(argesquema character varying, argtabla character varying, eventos character varying, extendida boolean, encascada boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
vinculadas refcursor; 
vinculada record;
existente record;

begin
select into existente * from log_tablas where esquema=argesquema and tabla=argtabla;
if not FOUND then
	if extendida then
	        perform log_agregar_log_ext(argesquema,argtabla, eventos);
	else
	        perform log_agregar_log(argesquema,argtabla, eventos);
	end if;
	if encascada then
	        open vinculadas for select distinct schemal.nspname as esquema, pg_class.relname as tabla from pg_constraint join pg_class on(pg_class.oid = conrelid) join pg_class as ref on(ref.oid=confrelid) join pg_namespace as schemaf on(ref.relnamespace=schemaf.oid) join pg_namespace as schemal on(schemal.oid = pg_class.relnamespace)  where contype='f' and ref.relname=argtabla and schemaf.nspname=argesquema and (concat(schemal.nspname,'.',pg_class.relname)) <> (concat(argesquema,'.',argtabla));
	        fetch vinculadas into vinculada;
	        while FOUND loop
	        select into existente * from log_tablas where esquema=vinculada.esquema::varchar and tabla=vinculada.tabla::varchar;
		if not FOUND then
			perform log_agregar_tabla(vinculada.esquema::varchar,vinculada.tabla::varchar,eventos::varchar,extendida,encascada);
	              --if extendida then
	              --      perform log_agregar_log_ext(vinculada.esquema::varchar, vinculada.tabla::varchar, eventos);
	              --else
	              --      perform log_agregar_log(vinculada.esquema::varchar, vinculada.tabla::varchar, eventos);
	              --end if;
	        end if;
	              fetch vinculadas into vinculada;
	        end loop;
	        close vinculadas;
	 end if;
	 
end if;
end;
$function$
