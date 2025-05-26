CREATE OR REPLACE FUNCTION public.auditoriamedica_conformulario_solicitarauditoria_darusos(pfiltros character varying)
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

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	 
	 IF rfiltros.accion = 'traertratamientoformulario' THEN
	 
       vnroorden = (rfiltros.nroformulario)::bigint / 100;
	   vcentro = (rfiltros.nroformulario)::bigint  % 100;
      SELECT INTO rformulariocompleto *,replace(replace(replace(replace(fmifdiagnostico,'"',''),'{',''),'}',''),',',' ') as diagnostico
	                                                 FROM fichamedicainfoformulario 
                                                            WHERE nullvalue(fmiffechafin) AND fmifnroorden = vnroorden 
                                                            AND	fmifcentro = vcentro;
       IF FOUND THEN 
				CREATE TEMP TABLE temp_auditoriamedica_planes_especiales  as (
				select key as clave, value as valor,rformulariocompleto.diagnostico as diagnostico,monodroga_uso.* from jsonb_each_text(rformulariocompleto.fmifformulario::jsonb) 
				JOIN monodroga_uso ON key ilike  concat(muformseccion,'%')  WHERE muenformulario 
				);
				
       END IF;
	   
	   END IF;
	   
	   IF rfiltros.accion = 'auditoriamedica_planes_especiales_traerformularios' THEN
		CREATE TEMP TABLE temp_auditoriamedica_planes_especiales AS (
			SELECT idfichamedicainfoformulario, idcentrofichamedicainfoformulario, fmiffechaingreso, fmimfidprestador 
				, nrodoc, tipodoc, fmifdiagnostico, fmifdiaobservacion 
			FROM fichamedicainfoformulario
			WHERE nrodoc = rfiltros.nrodoc
		);
	END IF;
	
	IF rfiltros.accion = 'auditoriamedica_planes_especiales_traerdetalleformulario' THEN
		CREATE TEMP TABLE temp_auditoriamedica_planes_especiales AS (
			SELECT idfichamedicainfoformulario, idcentrofichamedicainfoformulario, fmiffechaingreso, fmimfidprestador 
				, nrodoc, tipodoc, fmifdiagnostico, fmifdiaobservacion, 'clave'::varchar as tipoinformacion,'dato'::varchar as valorinformacion,'agrupador'::varchar as agrupador 
			FROM fichamedicainfoformulario
			WHERE idfichamedicainfoformulario = rfiltros.idfichamedicainfoformulario 
			AND idcentrofichamedicainfoformulario = rfiltros.idcentrofichamedicainfoformulario
		);
		SELECT INTO unaconfig * FROM fichamedicainfoformulario 
			WHERE idfichamedicainfoformulario = rfiltros.idfichamedicainfoformulario 
				AND  idcentrofichamedicainfoformulario  = rfiltros.idcentrofichamedicainfoformulario;
		INSERT INTO temp_auditoriamedica_planes_especiales (tipoinformacion,valorinformacion,agrupador) (
			SELECT key as tipoinformacion,value as valorinformacion,'fmifprestador' as agrupador FROM jsonb_each(unaconfig.fmifprestador) 
		); 
		INSERT INTO temp_auditoriamedica_planes_especiales (tipoinformacion,valorinformacion,agrupador) (
			SELECT key as tipoinformacion,value as valorinformacion,'fmiftratamiento' as agrupador FROM jsonb_each(unaconfig.fmiftratamiento) 
		); 
		INSERT INTO temp_auditoriamedica_planes_especiales (tipoinformacion,valorinformacion,agrupador) (
			SELECT key as tipoinformacion,value as valorinformacion,'fmifdiagnosticoj' as agrupador FROM jsonb_each(unaconfig.fmifdiagnosticoj) 
		);
		INSERT INTO temp_auditoriamedica_planes_especiales (tipoinformacion,valorinformacion,agrupador) (
			SELECT key as tipoinformacion,value as valorinformacion,'fmiflaboratorio' as agrupador FROM jsonb_each(unaconfig.fmiflaboratorio) 
		);
		INSERT INTO temp_auditoriamedica_planes_especiales (tipoinformacion,valorinformacion,agrupador) (
			SELECT key as tipoinformacion,value as valorinformacion,'fmifcomorbilidades' as agrupador FROM jsonb_each(unaconfig.fmifcomorbilidades) 
		);
	  END IF;
	   
     return 'Listo';
END;
$function$
