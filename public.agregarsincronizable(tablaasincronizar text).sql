CREATE OR REPLACE FUNCTION public.agregarsincronizable(tablaasincronizar text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	--Los nombres de los diferentes elementos que se van a crear	
	nombretrigger1 text;
	nombretrigger2 text;
	nombrestore text;
        nombrestoredelete text;
        crearstoredelete text;
	nombrecamposinc text;
	
	--Se utilizan para recorrer las claves primarias y los campos de la tabla	
	clavesprimarias REFCURSOR;
	campoclave record;
	campos REFCURSOR;
	campo record;
	
	--Los siguientes son los strings de las consultas
	agregarcampo text;
        valordefectocampo text;
	insertartabla text;
	creartrigger1 text;
	creartrigger2 text;
	crearstore1 text;
	crearstore2 text;
	crearstore3 text;
        listacamposinsert text;
	campoclavesinc text;
	creartabla text;
crear_pk text;
las_claves_pk text;
        creartablaenesquemas text;
        esq record;

	--auxiliares. La lista de campos a setear en el update, el where y en la creacion de la consulta
	setdelupdate text;
	wheredelupdate text;
	listadeclaracioncampos text;
	camposinsert text;
	aux boolean;


	
begin
    --Se setean los nombres de los elementos a crear en la base
    nombrecamposinc := concat ( tablaasincronizar , 'cc');
    nombretrigger1 :=concat (  'am' , tablaasincronizar);
    nombretrigger2 := concat ( 'ae' , tablaasincronizar);
    nombrestore :=concat (  'insertarcc' , tablaasincronizar);
    nombrestoredelete := concat ( 'eliminarcc',tablaasincronizar);


    --Armo la consulta para agregar el campo de control a la tabla
    agregarcampo := concat ( 'ALTER TABLE ' , tablaasincronizar , ' add column ' , nombrecamposinc , ' TIMESTAMP;');
      -- MaLaPi 08/08/2021 Modifico para que el crear el campo y asignar su valor por defecto se haga en 2 pasos.
    raise notice 'Agrega el campo de momento de sincronizacion: %',agregarcampo;
    execute agregarcampo;
    valordefectocampo := concat ( 'ALTER TABLE ' , tablaasincronizar , ' ALTER COLUMN ' , nombrecamposinc , ' SET DEFAULT current_timestamp;');
    execute valordefectocampo;
    valordefectocampo := concat ( 'update ' , tablaasincronizar , ' SET ' , nombrecamposinc , ' =  current_timestamp;');
    execute valordefectocampo;
	

    --Armo la lista de campos a setear en el update del trigger, la lista de declaraciones de campos
    --para la creacion de la tabla en el esquema sincro, y la lista de valores para el insert.
	setdelupdate:= '';
	listadeclaracioncampos:= '';
        camposinsert:='';
        listacamposinsert:='';

	open campos for
select distinct attname as nombre, typname as tipo from pg_class join pg_attribute on(oid = attrelid) join pg_type on 		(pg_attribute.atttypid = pg_type.oid)  join pg_namespace on (pg_class.relnamespace=pg_namespace.oid) where pg_namespace.nspname='public' and relname = tablaasincronizar and attnum >0;



	fetch campos into campo;
	while FOUND loop
		listadeclaracioncampos:= concat (  listadeclaracioncampos,campo.nombre, ' ' , campo.tipo);
		setdelupdate:= concat ( setdelupdate , campo.nombre , '= fila.',campo.nombre);
		camposinsert:= concat ( camposinsert , 'fila.',campo.nombre);
		listacamposinsert:= concat ( listacamposinsert , campo.nombre);
                fetch campos into campo;
		if FOUND then
			listadeclaracioncampos:=concat ( listadeclaracioncampos,', ');
			setdelupdate:= concat ( setdelupdate , ', ');			
			camposinsert:= concat ( camposinsert,', ');
            listacamposinsert:=concat (  listacamposinsert , ', ');
		end if;
	end loop;
	
    --Armo el where del update, con las claves primarias
	wheredelupdate:= '';
	
	open clavesprimarias for
--    	SELECT distinct attname as nombre FROM
--	(select * from pg_class join pg_constraint on (pg_class.oid = conrelid) where contype='p' and relname = 		tablaasincronizar) as res,
--		    (select * from pg_class join pg_attribute on(oid = attrelid) join pg_namespace on (pg_class.relnamespace=pg_namespace.oid) where attnum >0 and --pg_namespace.nspname='public') as columnas
--	    WHERE columnas.relname = res.relname and columnas.attnum = ANY (res.conkey) AND res.relnamespace = 2200;


--MaLaPi 14/02/2022 Cambio la consulta que obtiene la PK con el cambio del motor postgres 13
SELECT               
  pg_attribute.attname  as nombre 
  
FROM pg_index, pg_class, pg_attribute, pg_namespace 
WHERE 
  pg_class.oid = tablaasincronizar::regclass AND 
  indrelid = pg_class.oid AND 
  nspname = 'public' AND 
  pg_class.relnamespace = pg_namespace.oid AND 
  pg_attribute.attrelid = pg_class.oid AND 
  pg_attribute.attnum = any(pg_index.indkey)
 AND indisprimary;



	fetch clavesprimarias into campoclave;
	while FOUND loop
		wheredelupdate:= concat ( wheredelupdate,campoclave.nombre, '= fila.' , campoclave.nombre,' AND ');
                las_claves_pk := concat ( las_claves_pk, campoclave.nombre,',');
		fetch clavesprimarias into campoclave;
	end loop;
	wheredelupdate:= concat ( wheredelupdate,'TRUE');

    --Armo la declaracion de la tabla en el esquema de sincronizacion
	creartabla:= concat ( 'CREATE TABLE sincro.',tablaasincronizar , '(' , listadeclaracioncampos,');');

     -- vas 05/01/2021 armo la pk para la tabla 
     las_claves_pk  := rtrim(las_claves_pk,',');
     crear_pk := concat('ALTER TABLE sincro.', tablaasincronizar ,' ADD PRIMARY KEY (',las_claves_pk,');');


    --Armo la declaracion de la tabla en cada uno de los esquemas a sincronizar
creartablaenesquemas:='';        
For esq in select * from esquemasasincronizar loop
           creartablaenesquemas:= concat ( creartablaenesquemas,'CREATE TABLE ',esq.nombre ,'.',tablaasincronizar , '(' , listadeclaracioncampos,');');
           crear_pk := concat(crear_pk, ' ALTER TABLE ',esq.nombre ,'.', tablaasincronizar ,' ADD PRIMARY KEY (',las_claves_pk,');');
        END loop;



	raise notice 'Crea la tabla gemela en el esquema sincro: %',creartabla;

    -- Inserto la tabla en tablas a sincronizar
	insert into tablasasincronizar values(tablaasincronizar);
	select into aux * from ordenartablasasincronizar();

    -- Armo las consultas que crean los triggers para el update ,el insert y el delete
    	creartrigger1 := concat ( 'CREATE TRIGGER ',nombretrigger1 , ' BEFORE UPDATE OR INSERT
	    ON "public".',tablaasincronizar, ' FOR EACH ROW
	    EXECUTE PROCEDURE "public".',nombretrigger1,'();');
	raise notice 'Crea el trigger para el update de la tabla: %',creartrigger1;


creartrigger2 := concat ( 'CREATE TRIGGER ',nombretrigger2 , ' BEFORE DELETE
	    ON "public".',tablaasincronizar, ' FOR EACH ROW
	    EXECUTE PROCEDURE "public".',nombretrigger2,'();');
	raise notice 'Crea el trigger para el update de la tabla: %',creartrigger2;

    -- Armo las consultas que crean los stores que llaman los triggers

    crearstore1 := concat ( 'CREATE OR REPLACE FUNCTION "public".',nombretrigger1,
    '() RETURNS trigger AS
    $$
    BEGIN
    NEW:= ',nombrestore,'(NEW);
        return NEW;
    END;
    $$
    LANGUAGE ''plpgsql'' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER;');
	raise notice 'Crea el store del trigger para update: %',crearstore1;

crearstore2 := concat ( 'CREATE OR REPLACE FUNCTION "public".',nombretrigger2,
    '() RETURNS trigger AS
    $$
    BEGIN
    OLD:= ',nombrestoredelete,'(OLD);
        return OLD;
    END;
    $$
    LANGUAGE ''plpgsql'' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER;');
	raise notice 'Crea el store del trigger para update: %',crearstore2;
		
    --Se crea el store que hace el update o insert en el esquema sincro
    crearstore3 := concat ( 'CREATE OR REPLACE FUNCTION "public".',nombrestore
    ,'(fila ', tablaasincronizar, ') RETURNS ' , tablaasincronizar ,' AS
    $$
    BEGIN
    fila.',nombrecamposinc , ':= current_timestamp;','
    UPDATE sincro.',tablaasincronizar , ' SET ' , setdelupdate,' WHERE ', wheredelupdate,';
    IF NOT FOUND THEN
		INSERT INTO sincro.', tablaasincronizar , '(' , listacamposinsert , ') VALUES (', camposinsert,');
    END IF;
    RETURN fila;
    END;
    $$
    LANGUAGE ''plpgsql'' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER;');
    raise notice 'Store que registra la modificacion o insercion: %',crearstore3;


    --Se crea el store que hace el delete en el esquema sincro
    crearstoredelete := concat ( 'CREATE OR REPLACE FUNCTION "public".',nombrestoredelete
    ,'(fila ', tablaasincronizar, ') RETURNS ' , tablaasincronizar ,' AS
    $$
    BEGIN
    fila.',nombrecamposinc , ':= current_timestamp;','
    delete from sincro.',tablaasincronizar , ' WHERE ', wheredelupdate,';
    RETURN fila;
    END;
    $$
    LANGUAGE ''plpgsql'' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER;');
    raise notice 'Store que registra la modificacion o insercion: %',crearstore3;

    --Se ejecutan todas las acciones
    execute creartabla;
    execute creartablaenesquemas;  --vas 5/01/20 esto lo comento ya que no tenemos los esquemas de cada centro
    execute crear_pk;  --vas 5/01/20 le asigna una pk a la tabla
    execute crearstore3;
    execute crearstore2;
    execute crearstore1;
    execute crearstoredelete;
    execute creartrigger1;
    execute creartrigger2;

return 'true';
end;
$function$
