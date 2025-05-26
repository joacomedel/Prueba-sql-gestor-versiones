CREATE OR REPLACE FUNCTION public.turismo_abmturismounidadvalores()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	
	resultado RECORD;
	rusuario RECORD;
	
	
	elcursor refcursor;
	elem RECORD;
BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


OPEN elcursor FOR SELECT *
		from turismounidadvalor_temp;
		
FETCH elcursor into elem;
WHILE  found LOOP


	IF (elem.idturismounidadvalor is null OR elem.idturismounidadvalor = 0) THEN
		UPDATE turismounidadvalor SET tuvfechfin = elem.tuvfechaini 
		WHERE idturismounidadvalor = elem.idturismounidadvalor_anterior;

		INSERT INTO turismounidadvalor(idturismounidad,idturismotemporadatipos,tuvfechaini,tuvfechfin,tuvimporteinvitado,tuvimporteafiliado
				,tuvimportesosunc,tuvporpersona,tuvimporteinvitadososunc,idturismounidadvalortipo,idturismounidadusotipo,tuvcantidadunidaduso,
				tuvfactorcorreccionafiliado,tuvfactorcorreccionsosunc,tuvusuario) 
		VALUES(elem.idturismounidad,elem.idturismotemporadatipos,elem.tuvfechaini,elem.tuvfechafin,elem.tuvimporteinvitado,elem.tuvimporteafiliado
			,elem.tuvimportesosunc,elem.tuvporpersona,elem.tuvimporteinvitadososunc,elem.idturismounidadvalortipo,elem.idturismounidadusotipo,elem.tuvcantidadunidaduso,
			elem.tuvfactorcorreccionafiliado,elem.tuvfactorcorreccionsosunc,rusuario.idusuario);
        ELSE 
		UPDATE turismounidadvalor SET tuvfechfin = elem.tuvfechafin
			,idturismotemporadatipos=elem.idturismotemporadatipos
			,idturismounidad = elem.idturismounidad
			,tuvfechaini = elem.tuvfechaini
			,tuvimporteinvitado =elem.tuvimporteinvitado
			,tuvimporteafiliado = elem.tuvimporteafiliado
			,tuvimportesosunc=elem.tuvimportesosunc
			,tuvporpersona= elem.tuvporpersona
			,tuvimporteinvitadososunc = elem.tuvimporteinvitadososunc
			,idturismounidadvalortipo= elem.idturismounidadvalortipo
			,idturismounidadusotipo = elem.idturismounidadusotipo
			,tuvcantidadunidaduso = elem.tuvcantidadunidaduso
			,tuvfactorcorreccionafiliado = elem.tuvfactorcorreccionafiliado
			,tuvfactorcorreccionsosunc = elem.tuvfactorcorreccionsosunc
			,tuvusuario = rusuario.idusuario
			
		WHERE idturismounidadvalor = elem.idturismounidadvalor;
        END IF;
 
fetch elcursor into elem;
END LOOP;
close elcursor;		

return 'true';
END;
$function$
