CREATE OR REPLACE FUNCTION public.amtablavaloresxcategoria()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza la tabla de valores de un convenio
amtablavaloresxcategoria()
*/
DECLARE
	
	elem RECORD;
        aux RECORD;
        alta refcursor;  
	resultado boolean;
BEGIN

OPEN alta FOR SELECT * FROM temptablavalores 
                       ORDER BY temptablavalores.idconvenio,
                             temptablavalores.idtipounidad;
FETCH alta INTO elem;
WHILE  found LOOP

IF elem.valor::double precision <> 0 THEN 

   IF elem.accion = 'Modificar' THEN
      SELECT INTO aux * FROM tablavaloresxcategoria 
           WHERE  idtablavalor = elem.idtablavalor  
            AND idconvenio = elem.idconvenio
            AND idtipounidad = elem.idtipounidad 
            AND pcategoria = elem.pcategoria;
      IF FOUND THEN 
         UPDATE tablavaloresxcategoria SET idtipovalor = elem.valor::double precision
         WHERE idtablavalor = elem.idtablavalor  
            AND idconvenio = elem.idconvenio
            AND idtipounidad = elem.idtipounidad 
            AND pcategoria = elem.pcategoria;
      ELSE
          INSERT INTO tablavaloresxcategoria (idconvenio,idtablavalor,idtipounidad,idtipovalor,pcategoria) 
          VALUES (elem.idconvenio,elem.idtablavalor,elem.idtipounidad,elem.valor::double precision,elem.pcategoria);
      END IF;  
   END IF; 
   IF elem.accion = 'Agregar' THEN
      INSERT INTO tablavaloresxcategoria (idconvenio,idtablavalor,idtipounidad,idtipovalor,pcategoria) 
      VALUES (elem.idconvenio::integer,elem.idtablavalor,elem.idtipounidad,elem.valor::double precision,elem.pcategoria);
   END IF;
END IF;
    

FETCH alta INTO elem;
END LOOP;
CLOSE alta;

resultado = 'true';
RETURN resultado;
END;$function$
