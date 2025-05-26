CREATE OR REPLACE FUNCTION public.sincro_crearpk()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	tablas cursor for select * from tablasasincronizar order by orden;
	tabla record;
	columnas_pk record;
begin
    /* El propósito es crear las primary key de todas las tablas que son sincronizables y se encuentran en el esquema sincro
	*
	*/	
	open tablas;
	fetch tablas into tabla;	
	while FOUND loop
	    -- recorro cada una de las tablas
		-- actualiza la tabla para crear su primary key
		
		--raise notice 'Tabla: %',tabla.nombre;
		
		select into columnas_pk text_concatenar(concat(pg_attribute.attname,',')) as cols
				FROM   pg_namespace, pg_index, pg_attribute
				WHERE  pg_index.indrelid = tabla.nombre::regclass
				and	pg_attribute.attrelid = pg_index.indrelid
				and pg_attribute.attnum = ANY(pg_index.indkey)
				AND pg_index.indisprimary and nspname = 'public';
		
		columnas_pk.cols := rtrim(columnas_pk.cols,',');
		
		--raise notice 'Columnas de la PK: %', columnas_pk.cols;
		
		execute concat('ALTER TABLE sincro.', tabla.nombre ,' ADD PRIMARY KEY (',columnas_pk.cols,')');
				
		fetch tablas into tabla;
	end loop;
	close tablas;
return 'true';
end;
$function$
