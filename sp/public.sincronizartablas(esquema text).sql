CREATE OR REPLACE FUNCTION public.sincronizartablas(esquema text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	huboerror boolean:=false;
        --El nombre del esquema con el que se va a sincronizar
	--esquema alias for $1;

	--Contiene las tablas a sincronizar. Se supone que todas contienen un campo
	--que se llama <nombretabla>_modificacion.
	tablas CURSOR FOR select relname as nombre from pg_class join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) join tablasasincronizar on (relname = nombre) where nspname=esquema order by orden;
	tabla RECORD;
	--Contendra las tablas relacionadas con las tablas a sincronizar
	tablasrelacionadas refcursor;
	tablarel record;
	haynuevas boolean;
	
	--Contendra por cada tabla a sincronizar, los campos que integran
	--la clave primaria de la tabla.
	clavesprimarias REFCURSOR;
	campoclave RECORD;

	--Contendra por cada tabla a sincronizar, todos los campos
	--de la tabla
	campos REFCURSOR;
	campo RECORD;
	
	--Contendran las consultas para actualizar la tabla
	updatetabla text;
	inserttabla text;
	selecttabla text;
	listaclave text;
	listaclaveconnull text;
	listacampos text;
       	listacamposselect text;
	aux text;
	
begin
	open tablas;
	fetch tablas into tabla;
	while FOUND and (not huboerror) loop
        begin
		-- Se deshabilitan todos los triggers de la tabla
                
                EXECUTE concat('ALTER TABLE ',tabla.nombre , ' DISABLE TRIGGER all');
                --EXECUTE concat('ALTER TABLE ',tabla.nombre , ' DISABLE TRIGGER am' , tabla.nombre , ';');
                --EXECUTE concat('ALTER TABLE ',tabla.nombre , ' DISABLE TRIGGER ae' , tabla.nombre , ';');

		--Se crean las consultas que obtienen los campos
		--y los campos clave de la tabla
		open campos for
			select distinct attname as nombrecampo from pg_class join pg_attribute on(oid = attrelid) join pg_namespace on(pg_namespace.oid=relnamespace) where relname = tabla.nombre and attnum >0 and not attisdropped and nspname='public';
		open clavesprimarias for
			--SELECT distinct attname as nombrecampo FROM
			--(
			--	select * from pg_class join pg_constraint on(pg_class.oid = conrelid) where contype='p'
			--) as res,
			--(
			--	select relname, attname, attnum from pg_class join pg_attribute on(oid = attrelid) join pg_namespace on(pg_namespace.oid=relnamespace) where attnum >0 and not attisdropped and relname=tabla.nombre and nspname='public'
	--		) as columnas
	--		WHERE columnas.relname = res.relname and res.relname=tabla.nombre 
          --                    and columnas.attnum = ANY (res.conkey);
                              --12/02/2022 Malapi lo comenta and  connamespace=2200;  --vas 11-12-2020
--MaLaPi 14/02/2022 Cambio la consulta que obtiene la PK con el cambio del motor postgres 13
SELECT               
  pg_attribute.attname  as nombrecampo 
  
FROM pg_index, pg_class, pg_attribute, pg_namespace 
WHERE 
  pg_class.oid = tabla.nombre::regclass AND 
  indrelid = pg_class.oid AND 
  nspname = 'public' AND 
  pg_class.relnamespace = pg_namespace.oid AND 
  pg_attribute.attrelid = pg_class.oid AND 
  pg_attribute.attnum = any(pg_index.indkey)
 AND indisprimary;

		
		--Se debe crear una cadena que contenga el update y otra el insert
		--correspondiente a la tabla
                updatetabla := concat('UPDATE ' , tabla.nombre , ' SET ');
		
		--Se agregan los set de los campos de la tabla a la cadena
		--Se crea la lista de campos de la tabla entre parentesis
		--para utilizarla en el insert
		listacamposselect := '';
                listacampos := '(';
		fetch campos into campo;
		while FOUND loop
			updatetabla:=concat(updatetabla , campo.nombrecampo , '=' ,
					tabla.nombre,'2','.',campo.nombrecampo);
			listacampos:=concat(listacampos,campo.nombrecampo);
                        listacamposselect:=concat(listacamposselect,tabla.nombre,'2.',campo.nombrecampo);
			fetch campos into campo;
			if FOUND then
				updatetabla:=concat(updatetabla,', ');
				listacampos:=concat(listacampos,', ');
                                listacamposselect:=concat(listacamposselect,', ');
			end if;
		end loop;
		close campos;
		listacampos:=concat(listacampos,')');
		--Se agrega la tabla del esquema en la clausula from
		updatetabla:=concat(updatetabla,' FROM ' , esquema , '.' , tabla.nombre , ' as ' , tabla.nombre,'2');
		
		--Se agrega el where que compara las claves primarias
		--y a la par se crea un string con la lista de los campos
		--de la clave primaria entre parentesis separados por comas,
		--para ser usado luego en el insert
		listaclave:='(';
		listaclaveconnull:='';
		updatetabla := concat(updatetabla , ' WHERE ');
		fetch clavesprimarias into campoclave;
		while FOUND loop
			updatetabla:=concat(updatetabla , tabla.nombre,'.',campoclave.nombrecampo , '=' ,
					tabla.nombre,'2','.', campoclave.nombrecampo , ' AND ');
			listaclave:=concat(listaclave,campoclave.nombrecampo);
			listaclaveconnull:=concat(listaclaveconnull , tabla.nombre,'.', campoclave.nombrecampo , ' is null');
			fetch clavesprimarias into campoclave;
                        if FOUND then
				listaclave:=concat(listaclave,', ');
				listaclaveconnull:=concat(listaclaveconnull , ' and ');
			end if;
		end loop;
		close clavesprimarias;
		listaclave:=concat(listaclave,')');

		--Se agrega la comparacion de las fechas de modificacion de la tabla
		updatetabla := concat(updatetabla , '((',tabla.nombre,'.',tabla.nombre,'cc < ' , tabla.nombre,'2','.',tabla.nombre,'cc ))');
		--Solo para verificar que el update generado sea correcto
		RAISE NOTICE '%', updatetabla;
		
		--Se crea el insert de las tuplas nuevas en el esquema con el
		--que se sincroniza
		inserttabla:= concat(' INSERT INTO ' , tabla.nombre , listacampos , ' SELECT ' , listacamposselect , ' FROM ' ,
				esquema , '.' , tabla.nombre , ' as ' , tabla.nombre,'2 LEFT OUTER JOIN ',tabla.nombre , ' USING', listaclave,' WHERE ',listaclaveconnull , ';');
		selecttabla:= concat('select EXISTS(SELECT ' ,tabla.nombre , '2.* FROM ' ,
				esquema , '.' , tabla.nombre , ' as ' , tabla.nombre,'2 LEFT OUTER JOIN ',tabla.nombre , ' USING', listaclave,' WHERE ',listaclaveconnull , ');');
		
		
		
		--Solo para verificar que el insert generado sea correcto
		--RAISE NOTICE '%', inserttabla;



		--Se ejecutan las dos consultas
		--raise notice '%', updatetabla;
                --raise notice '%', inserttabla;
                EXECUTE updatetabla;
		EXECUTE selecttabla INTO haynuevas;
		RAISE NOTICE '%', selecttabla;
		IF haynuevas THEN
			RAISE NOTICE 'PASO POR ACA 2';
			EXECUTE inserttabla;
		END IF;
                EXECUTE concat('ALTER TABLE ',tabla.nombre , ' ENABLE TRIGGER all');
                --EXECUTE concat('ALTER TABLE ',tabla.nombre , ' ENABLE TRIGGER am' , tabla.nombre , ';');
                --EXECUTE concat('ALTER TABLE ',tabla.nombre , ' ENABLE TRIGGER ae' , tabla.nombre , ';');
                fetch tablas into tabla;
--	exception when others then
--                 INSERT INTO logsincro(descripcionlogsincro) values(concat('Ocurrio un error cuando se intentaba sincronizar  ',esquema --, '.' , tabla.nombre));
--
--                 huboerror:=true;
        end;
        end loop;
	close tablas;
if(huboerror) then
return false;
end if;
return 'true';
end;
$function$
