CREATE OR REPLACE FUNCTION public.sincro_generaupdatemasivos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	tablas cursor for select * from tablasasincronizar order by orden;
	tabla record;
	columnas_pk record;
        vconsulta varchar;
rfiltros record;
begin
    /* El propósito es crear las primary key de todas las tablas que son sincronizables y se encuentran en el esquema sincro
	*
	*/	
 EXECUTE sys_dar_filtros($1) INTO rfiltros;
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
				AND pg_index.indisprimary and nspname = 'public'
AND pg_attribute.attname ilike '%centro%';
                IF FOUND AND not nullvalue(columnas_pk.cols) THEN
                    columnas_pk.cols := rtrim(columnas_pk.cols,',');
                    IF     POSITION( ',' in  columnas_pk.cols ) >0 THEN
                             raise notice 'Tiene mas de 1 centro % >>> en %', columnas_pk.cols,  tabla.nombre;
                           --  raise notice 'Columnas centro en la PK: %', columnas_pk.cols;
                    END IF;
                 END IF;		

		
                --SELECT INTO unrec columnas_pk.cols ilike '%centro%';  
                 
		
		--raise notice 'Columnas de la PK: %', columnas_pk.cols;
		
		--execute concat('UPDATE ', tabla.nombre ,' SET ', tabla.nombre,'cc', '=',tabla.nombre, 'cc',' WHERE ',tabla.nombre,'cc',' >= ', rfiltros.fechadesde, ' AND ' tabla.nombre,'cc <= ',rfiltros.fechahasta);
                vconsulta = concat('UPDATE ', tabla.nombre ,' SET ', tabla.nombre,'cc', '=',tabla.nombre, 'cc',' WHERE ',tabla.nombre,'cc',' >= ''', rfiltros.fechadesde, ''' AND ', tabla.nombre,'cc <= ''',rfiltros.fechahasta, '''');
		execute vconsulta;
		
               raise notice '%',vconsulta ;	
				
		fetch tablas into tabla;
	end loop;
	close tablas;
return 'true';
end;
$function$
