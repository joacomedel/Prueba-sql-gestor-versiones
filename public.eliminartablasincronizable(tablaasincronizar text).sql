CREATE OR REPLACE FUNCTION public.eliminartablasincronizable(tablaasincronizar text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	--Los nombres de los diferentes elementos que se van a crear	
	nombretrigger1 text;
	nombretrigger2 text;
	nombrestore text;
	nombrecamposinc text;
	
	--Se utilizan para recorrer las claves primarias y los campos de la tabla	
	clavesprimarias REFCURSOR;
	campoclave record;
	campos REFCURSOR;
	campo record;
	
	--Los siguientes son los strings de las consultas
	agregarcampo text;
	insertartabla text;
	creartrigger1 text;
	creartrigger2 text;
	crearstore1 text;
	crearstore2 text;
	crearstore3 text;
        crearstore4 text;
        nombrestore2 text;
	campoclavesinc text;
	creartabla text;
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
    nombrecamposinc := concat(tablaasincronizar , 'cc');
    nombretrigger1 := concat('am' , tablaasincronizar);
    nombretrigger2 := concat('ae' , tablaasincronizar);
    nombrestore := concat('insertarcc' , tablaasincronizar);
    nombrestore2 := concat('eliminarcc' , tablaasincronizar);


    --Armo la consulta para agregar el campo de control a la tabla
    agregarcampo := concat('ALTER TABLE ' , tablaasincronizar , ' DROP column '
    , nombrecamposinc , ';');
    raise notice 'Elimino el campo: %',agregarcampo;
    execute agregarcampo;
	

    --Armo la lista de campos a setear en el update del trigger, la lista de declaraciones de campos
    --para la creacion de la tabla en el esquema sincro, y la lista de valores para el insert.
	setdelupdate:= '';
	listadeclaracioncampos:= '';
        camposinsert:='';

	open campos for
	select attname as nombre, typname as tipo from pg_class join pg_attribute on(oid = attrelid) join pg_type on 		(pg_attribute.atttypid = pg_type.oid) where relname = tablaasincronizar and attnum >0;

	fetch campos into campo;
	while FOUND loop
		listadeclaracioncampos:= concat(listadeclaracioncampos,campo.nombre, ' ' , campo.tipo);
		setdelupdate:= concat(setdelupdate , campo.nombre , '= fila.',campo.nombre);
		camposinsert:= concat(camposinsert , 'fila.',campo.nombre);
		fetch campos into campo;
		if FOUND then
			listadeclaracioncampos:=concat(listadeclaracioncampos,', ');
			setdelupdate:= concat(setdelupdate , ', ');			
			camposinsert:= concat(camposinsert,', ');
		end if;
	end loop;
	

    -- Elimino la tabla en el esquema de sincronizacion
	creartabla:= concat('DROP TABLE sincro.',tablaasincronizar , ';');
	raise notice 'Elimino la tabla gemela en el esquema sincro: %',creartabla;

--Armo la declaracion de la tabla en cada uno de los esquemas a sincronizar
creartablaenesquemas:='';        
For esq in select * from esquemasasincronizar loop
               creartablaenesquemas:= concat(creartablaenesquemas,'DROP TABLE ',esq.nombre ,'.',tablaasincronizar ,';');
        END loop;





    -- Elimino la tabla en tablas a sincronizar
    DELETE FROM tablasasincronizar WHERE tablasasincronizar.nombre = tablaasincronizar;
	select into aux * from ordenartablasasincronizar();

  -- Armo las consultas que eliminan los para el update y el insert
    	creartrigger1 := concat('DROP TRIGGER ',nombretrigger1 , '
	    ON "public".',tablaasincronizar, ' ;');
	raise notice 'Elimino el trigger para el update de la tabla: %',creartrigger1;


        creartrigger2 := concat('DROP TRIGGER ',nombretrigger2 ,'
	    ON "public".',tablaasincronizar, ' ;');
	raise notice 'Elimono el trigger para el update de la tabla: %',creartrigger2;
	
	-- Armo las consultas que eliminan  los stores que llaman los triggers

    crearstore1 := concat('DROP FUNCTION "public".',nombretrigger1, '();');
	raise notice 'Elimina el store del trigger para update: %',crearstore1;

    crearstore2 := concat('DROP FUNCTION "public".',nombretrigger2, '();');
	raise notice 'Elimina el store del trigger para update: %',crearstore2;
		
    -- Se elimina  el store que hace el update o insert en el esquema sincro
    crearstore3 := concat('DROP FUNCTION "public".',nombrestore,'(fila ', tablaasincronizar, ');');
    raise notice 'Elimna el Store que registra la modificacion o insercion: %',crearstore3;

    -- Se elimina  el store que hace el update o insert en el esquema sincro
    crearstore4 := concat('DROP FUNCTION "public".',nombrestore2,'(fila ', tablaasincronizar, ');');
    raise notice 'Elimna el Store que registra la eliminacion: %',crearstore3;




    --Se ejecutan todas las acciones
    execute creartabla;
    execute creartablaenesquemas; ----vas 5/01/20 esto lo comento ya que no tenemos los esquemas de cada centro
    execute creartrigger1;
    execute creartrigger2;
    execute crearstore3;
    execute crearstore2;
    execute crearstore1;
    execute crearstore4;

return true;
end;
$function$
