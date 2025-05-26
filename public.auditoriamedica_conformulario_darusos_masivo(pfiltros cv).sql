CREATE OR REPLACE FUNCTION public.auditoriamedica_conformulario_darusos_masivo(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       cvalormedicamento refcursor;
       unvalormed record;
       unvalormedanterior record;
       primero boolean;
        
        rfiltros RECORD;
        rusuario RECORD;
        vfiltroid varchar;
        vparametrojson jsonb;
        vrespuestajson jsonb;
		
		vnroorden BIGINT;
		vcentro BIGINT;
		unaconfig RECORD;
		rformulariocompleto RECORD;
      
BEGIN 
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
--idfichamedicainfoformulario	idcentrofichamedicainfoformulario
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	 
	 OPEN cvalorregistros FOR SELECT *,replace(replace(replace(replace(fmifdiagnostico,'"',''),'{',''),'}',''),',',' ') as diagnostico
	                                                 FROM fichamedicainfoformulario 
                                                     WHERE nullvalue(fmiffechafin)
 		--LIMIT 10
		;
	   FETCH cvalorregistros INTO unvalorreg ;
		WHILE  found LOOP 
		
		IF not iftableexists('temp_auditoriamedica_planes_especiales') THEN 
			CREATE TEMP TABLE temp_auditoriamedica_planes_especiales AS (
			SELECT idfichamedicainfoformulario, idcentrofichamedicainfoformulario, fmiffechaingreso, fmimfidprestador 
				, nrodoc, tipodoc, fmifdiagnostico, fmifdiaobservacion, 'clave'::varchar as tipoinformacion,'dato'::varchar as valorinformacion,'agrupador'::varchar as agrupador 
			    ,0 as idmonodrogauso, 0 as idmonodroga, '' as 	muuso,'' as	muenformulario, '' as muformseccion,'' as diagnostico
			FROM fichamedicainfoformulario
			WHERE idfichamedicainfoformulario = unvalorreg.idfichamedicainfoformulario 
			AND idcentrofichamedicainfoformulario = unvalorreg.idcentrofichamedicainfoformulario
		);
		ELSE
			INSERT INTO temp_auditoriamedica_planes_especiales (
			SELECT idfichamedicainfoformulario, idcentrofichamedicainfoformulario, fmiffechaingreso, fmimfidprestador 
				, nrodoc, tipodoc, fmifdiagnostico, fmifdiaobservacion, 'clave'::varchar as tipoinformacion,'dato'::varchar as valorinformacion,'agrupador'::varchar as agrupador 
			    ,0 as idmonodrogauso, 0 as idmonodroga, '' as 	muuso,'' as	muenformulario, '' as muformseccion,'' as diagnostico
			FROM fichamedicainfoformulario
			WHERE idfichamedicainfoformulario = unvalorreg.idfichamedicainfoformulario 
			AND idcentrofichamedicainfoformulario = unvalorreg.idcentrofichamedicainfoformulario
		);
		
		END IF;
		
		SELECT INTO unaconfig * FROM fichamedicainfoformulario 
			WHERE idfichamedicainfoformulario = unvalorreg.idfichamedicainfoformulario 
				AND  idcentrofichamedicainfoformulario  = unvalorreg.idcentrofichamedicainfoformulario;
				
		INSERT INTO temp_auditoriamedica_planes_especiales (idfichamedicainfoformulario,idcentrofichamedicainfoformulario,tipoinformacion,valorinformacion,agrupador) (
			SELECT  unvalorreg.idfichamedicainfoformulario  as idfichamedicainfoformulario, unvalorreg.idcentrofichamedicainfoformulario  as idcentrofichamedicainfoformulario,key as tipoinformacion,value as valorinformacion,'fmifprestador' as agrupador FROM jsonb_each(unaconfig.fmifprestador) 
		); 
		INSERT INTO temp_auditoriamedica_planes_especiales (idfichamedicainfoformulario,idcentrofichamedicainfoformulario,tipoinformacion,valorinformacion,agrupador) (
			SELECT unvalorreg.idfichamedicainfoformulario  as idfichamedicainfoformulario, unvalorreg.idcentrofichamedicainfoformulario  as idcentrofichamedicainfoformulario,key as tipoinformacion,value as valorinformacion,'fmiftratamiento' as agrupador FROM jsonb_each(unaconfig.fmiftratamiento) 
		); 
		INSERT INTO temp_auditoriamedica_planes_especiales (idfichamedicainfoformulario,idcentrofichamedicainfoformulario,tipoinformacion,valorinformacion,agrupador) (
			SELECT unvalorreg.idfichamedicainfoformulario  as idfichamedicainfoformulario, unvalorreg.idcentrofichamedicainfoformulario  as idcentrofichamedicainfoformulario,key as tipoinformacion,value as valorinformacion,'fmifdiagnosticoj' as agrupador FROM jsonb_each(unaconfig.fmifdiagnosticoj) 
		);
		INSERT INTO temp_auditoriamedica_planes_especiales (idfichamedicainfoformulario,idcentrofichamedicainfoformulario,tipoinformacion,valorinformacion,agrupador) (
			SELECT unvalorreg.idfichamedicainfoformulario  as idfichamedicainfoformulario, unvalorreg.idcentrofichamedicainfoformulario  as idcentrofichamedicainfoformulario,key as tipoinformacion,value as valorinformacion,'fmiflaboratorio' as agrupador FROM jsonb_each(unaconfig.fmiflaboratorio) 
		);
		INSERT INTO temp_auditoriamedica_planes_especiales (idfichamedicainfoformulario,idcentrofichamedicainfoformulario,tipoinformacion,valorinformacion,agrupador) (
			SELECT unvalorreg.idfichamedicainfoformulario  as idfichamedicainfoformulario, unvalorreg.idcentrofichamedicainfoformulario  as idcentrofichamedicainfoformulario,key as tipoinformacion,value as valorinformacion,'fmifcomorbilidades' as agrupador FROM jsonb_each(unaconfig.fmifcomorbilidades) 
		);
		INSERT INTO temp_auditoriamedica_planes_especiales (idfichamedicainfoformulario,idcentrofichamedicainfoformulario,tipoinformacion,valorinformacion,diagnostico,idmonodrogauso,idmonodroga,muuso,muenformulario,muformseccion) (
				select unvalorreg.idfichamedicainfoformulario  as idfichamedicainfoformulario, unvalorreg.idcentrofichamedicainfoformulario  as idcentrofichamedicainfoformulario,key as tipoinformacion, value as valorinformacion,unvalorreg.diagnostico as diagnostico,monodroga_uso.* 
					from jsonb_each_text(unvalorreg.fmifformulario::jsonb) 
				     JOIN monodroga_uso ON key ilike  concat(muformseccion,'%')  
				WHERE muenformulario 
				);
		RAISE NOTICE 'Listas las Drogas ';
		 	
		UPDATE 	temp_auditoriamedica_planes_especiales SET valorinformacion = replace(valorinformacion,'"','');
		FETCH cvalorregistros INTO unvalorreg ;
		END LOOP;
		CLOSE cvalorregistros;
	 
	 
	
	   
     return 'Listo';
END;
$function$
