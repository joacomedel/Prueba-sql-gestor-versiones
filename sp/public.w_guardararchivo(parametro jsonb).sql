CREATE OR REPLACE FUNCTION public.w_guardararchivo(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
  /* SELECT * FROM public.w_guardararchivo('{ "nrodoc":"1234", "tipodoc":"1", "nroorden": "4321", "tipoorden": "4321", "centroorden": "1", "nombretablaasoc":"w_turnoarchivo", "valoraciones": [{"id": "IDVAL", "valor":(0-5)}, {...}, ... ], "observacion": "TEST"}')*/
--SELECT w_guardararchivo('{"tipo":"turno","ardescripcion":"Form. Solicitud atencion afiliado","datosasoc":{"idcentroturno":1,"idturno":1059},"uwnombre":"ususimosa","archivossubidos":[{"name":"Captura de pantalla de 2022-05-19 09-32-52.png","type":"image\/png","tmp_name":"\/tmp\/phpr6oHCu","error":0,"size":352615,"arnombre":"Captura de pantalla de 2022-05-19 09-32-52.png","accion":"nuevo","arubicacion":"\/var\/www\/html\/wwwsiges\/uploaded_files\/turno\/","arextension":"png","idusuarioweb":null,"ardescripcion":"Form. Solicitud atencion afiliado","idarchivo":"1332","idcentroarchivo":1,"nombreArchivo":"e430f779f7ff81de0e5b4c4f5e316672.png"},{"name":"Captura de pantalla de 2022-05-19 09-33-49.png","type":"image\/png","tmp_name":"\/tmp\/phpNOYobu","error":0,"size":329983,"arnombre":"Captura de pantalla de 2022-05-19 09-33-49.png","accion":"nuevo","arubicacion":"\/var\/www\/html\/wwwsiges\/uploaded_files\/turno\/","arextension":"png","idusuarioweb":null,"ardescripcion":"Form. Solicitud atencion afiliado","idarchivo":"1333","idcentroarchivo":1,"nombreArchivo":"f055c54d16a8cc75a8cc996511cc9a9c.png"}]}')

DECLARE
	vtipo varchar;	
	varchivos text;
	varchivostipo text;
	vdatosasoc jsonb;
	
	i int := 1;	
	sqlstr varchar;
	sqlins varchar;	
	varchivo jsonb;		
	arrarchivos jsonb[];
	arrarchivostipo jsonb[];
	res varchar;	
	respuestajson jsonb;
	 tipo_archivo INTEGER;

BEGIN
	vtipo = parametro ->> 'tipo';
	varchivos = parametro ->> 'archivossubidos';
	varchivostipo = parametro ->> 'archivostipo';	
	vdatosasoc = parametro ->> 'datosasoc';
	
	IF vtipo IS null OR varchivos IS null OR vdatosAsoc IS null THEN
		RAISE EXCEPTION 'R-001 WS_guardararchivo, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %', parametro;
	END IF;
	
	FOR varchivo IN (SELECT jsonb_array_elements(varchivos::jsonb)) LOOP
		arrarchivos[i] := varchivo;
		i := i+1;		
	END LOOP;
	
	IF (coalesce(array_length(arrarchivos,1),0) = 0) THEN
		RAISE EXCEPTION 'R-002 WS_guardararchivo, Parámetro Inválido: No se recibieron archivos.';
	END IF;
	
	sqlstr = 'INSERT INTO ';
	CASE vtipo
		WHEN 'turno' THEN			
			-- TODO: extraer valores y claves para que sea dinamico?		
			sqlstr = concat(sqlstr, 'w_turnoarchivo (idturno, idcentroturno, idarchivo, idcentroarchivo, idturnoarchivotipo) ');			
			sqlstr = concat(sqlstr, 'VALUES (', vdatosasoc->>'idturno',',', vdatosasoc->>'idcentroturno',',');		
		ELSE
			RAISE EXCEPTION 'R-003 WS_guardararchivo, Tipo Inválido, revíselos y envíelos nuevamente. Parámetros: %', parametro;
	END CASE;
		
	--TODO: se puede verificar que los archivos tengan los datos de id requeridos
	-- Se asocian los archivos enviados en la tabla de relación correspondiente
	FOR i IN 1 .. array_length(arrarchivos, 1) LOOP
		varchivo := arrarchivos[i];

		IF (varchivostipo IS NOT NULL) THEN
			tipo_archivo := (varchivostipo::jsonb -> i::INTEGER - 1 ->> 'tipo')::INTEGER;
		END IF;
		
		-- RAISE EXCEPTION 'R-003 WS_guardararchivo, Tipo Inválido, revíselos y envíelos nuevamente. Parámetros: %', tipo_archivo ;
		IF tipo_archivo IS NULL THEN
			sqlins := concat(sqlstr, varchivo->>'idarchivo', ',', varchivo->>'idcentroarchivo', ',', '2', ')');
		ELSE
			sqlins := concat(sqlstr, varchivo->>'idarchivo', ',', varchivo->>'idcentroarchivo', ',', tipo_archivo::text, ')');
		END IF;
		-- sqlins := concat(sqlstr, varchivo->>'idarchivo', ',', varchivo->>'idcentroarchivo', ',', tipo_archivo, ')');
		EXECUTE sqlins;
	END LOOP;


-- 	FOR i IN 1 .. array_length(arrarchivos, 1) LOOP
-- 	varchivo := arrarchivos[i];

-- 	-- Si cada archivo tiene su tipo, lo sacamos del mismo archivo
-- 	IF varchivo ? 'tipo' THEN
-- 		tipo_archivo := (varchivo->>'tipo')::INTEGER;
-- 	ELSIF varchivostipo IS NOT NULL AND (varchivostipo::jsonb -> 'archivosTipo') ? (i - 1)::text THEN
-- 		tipo_archivo := (varchivostipo::jsonb -> 'archivosTipo' -> (i - 1) ->> 'tipo')::INTEGER;
-- 	ELSE
-- 		tipo_archivo := NULL; -- o podés hacer que falle acá
-- 	END IF;

-- 	IF tipo_archivo IS NULL THEN
-- 		RAISE EXCEPTION 'R-004 WS_guardararchivo: No se pudo determinar el tipo del archivo en posición %', i;
-- 	END IF;

-- 	EXECUTE sqlstr USING 
-- 		(vdatosasoc->>'idturno')::INTEGER,
-- 		(vdatosasoc->>'idcentroturno')::INTEGER,
-- 		(varchivo->>'idarchivo')::INTEGER,
-- 		(varchivo->>'idcentroarchivo')::INTEGER,
-- 		tipo_archivo;
-- END LOOP;


	
	res = concat('{ "res" : "true" ,"mensaje" : "Archivos guardados exitosamente", "archivos":[',string_agg(trim(array_to_string(arrarchivos, ','), '"'), ', '),']}');
	respuestajson = concat('{"guardararchivo":', res, '}');
	return respuestajson;
END

$function$
