CREATE OR REPLACE FUNCTION public.actualizartablasincro(tablaasincronizar text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
campos refcursor;
campo record;
creartabla text :='';
listadeclaracioncampos text :='';
listacamposinsert text :='';
aux record;
begin
open campos for
select distinct attname as nombre, typname as tipo from pg_class join pg_attribute on(oid = attrelid) join pg_type on 		(pg_attribute.atttypid = pg_type.oid)  join pg_namespace on (pg_class.relnamespace=pg_namespace.oid) where pg_namespace.nspname='sincro' and relname = tablaasincronizar and attnum >0;



	fetch campos into campo;
	while FOUND loop
		listadeclaracioncampos:= concat ( listadeclaracioncampos,campo.nombre, ' ' , campo.tipo);
		listacamposinsert:= concat ( listacamposinsert , campo.nombre);
                fetch campos into campo;
		if FOUND then
			listadeclaracioncampos:=concat ( listadeclaracioncampos,', ');
			listacamposinsert:= concat ( listacamposinsert,', ');
		end if;
	end loop;
	close campos;

	creartabla:= concat ( 'CREATE TEMP TABLE sincro_t',tablaasincronizar , '(' , listadeclaracioncampos,');');
	execute creartabla;
	execute concat ( 'insert into sincro_t',tablaasincronizar,'(',listacamposinsert,') select ',listacamposinsert,' from sincro.',tablaasincronizar,';');
	select into aux eliminartablasincronizable(tablaasincronizar);
	select into aux agregarsincronizable(tablaasincronizar);
	execute concat ( 'insert into sincro.',tablaasincronizar,'(',listacamposinsert,') select ',listacamposinsert,' from sincro_t',tablaasincronizar,';');
return 'true';
end;
$function$
