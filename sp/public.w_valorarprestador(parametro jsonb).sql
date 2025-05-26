CREATE OR REPLACE FUNCTION public.w_valorarprestador(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ /* SELECT * FROM public.w_valorarPrestador('{ "nrodoc":"1234", "tipodoc":"1", "nroorden": "4321", "tipoorden": "4321", "centroorden": "1", "idprestador": "idpres", "valoraciones": [{"id": "IDVAL", "valor":(0-5)}, {...}, ... ], "observacion": "TEST"}')*/
DECLARE
	respuestajson jsonb;
	rpersona record;
	
	vnrodoc varchar;
	vtipodoc varchar;
	vnroorden varchar;
	vtipoorden varchar;
	vcentroorden varchar;
	vidprestador varchar;
	vvaloraciones text;
	vvaloracion jsonb;
	vobservacion varchar(255);	
	
	i int := 1;
	arrvaloraciones jsonb[];
	rordenvalida RECORD;
	vidvalins integer;
BEGIN
	vnrodoc = parametro ->> 'nrodoc';
	vtipodoc = parametro ->> 'tipodoc';
	vnroorden = parametro ->> 'nroorden';
	vtipoorden = parametro ->> 'tipoorden';
	vcentroorden = parametro ->> 'centroorden';
	vidprestador = parametro ->> 'idprestador';
	vvaloraciones = parametro ->> 'valoraciones';
	vobservacion = parametro ->> 'observacion';
	
	IF (vnrodoc IS NULL OR vtipodoc IS NULL OR vnroorden IS NULL OR vtipoorden IS NULL OR vcentroorden IS NULL OR vidprestador IS NULL OR vvaloraciones IS NULL) THEN
		RAISE EXCEPTION 'R-001 WS_valorarprestador, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;
	
	--Se extraen las valoraciones recibidas a un arr	
	FOR vvaloracion IN (SELECT jsonb_array_elements(vvaloraciones::jsonb)) LOOP
		arrvaloraciones[i] := vvaloracion;
		i := i+1;		
	END LOOP;	
	
	--El arreglo vacío retorna null en su longitud, entonces se retorna 0
	IF (coalesce(array_length(arrvaloraciones,1),0) = 0) THEN
		RAISE EXCEPTION 'R-008 WS_valorarprestador, Parámetro Inválido: Valoraciones Vacías.';
	END IF;
	
	--Verifica orden valida para el usr,	
	SELECT INTO rordenvalida nroorden, centro, idosreci,idprestador, fechauso, importe, fechaauditoria, nromatricula, malcance, mespecialidad, idplancobertura, nrodocuso, tipodocuso, tipo, ordenesutilizadascc
		FROM ordenesutilizadas
		WHERE nroorden = vnroorden AND tipo = vtipoorden AND centro = vcentroorden AND nrodocuso = vnrodoc AND tipodocuso = vtipodoc;
	IF NOT FOUND THEN
		SELECT INTO rordenvalida nroorden, centro, idosreci,idprestador, fechauso, importe, fechaauditoria, uso.nromatricula, uso.malcance, uso.mespecialidad, idplancobertura, nrodocuso, tipodocuso, tipo, ordenesutilizadascc
		FROM consumo
		NATURAL JOIN orden
		JOIN ordvalorizada USING(nroorden,centro)
		LEFT JOIN ordenesutilizadas AS uso USING(nroorden,centro,tipo)		 
		--AND idprestador = vidprestador
		WHERE nroorden = vnroorden AND tipo = vtipoorden AND centro = vcentroorden AND nrodoc = vnrodoc AND nullvalue(uso.nroorden) AND NOT anulado
		ORDER BY idprestador, fechauso DESC, fechaauditoria DESC;
		IF NOT FOUND THEN
			RAISE EXCEPTION 'R-009 WS_valorarprestador, El usuario no se atendió con el prestador seleccionado, inténtelo nuevamente o comuníquese con soporte.';
		END IF;
	END IF;
	
	BEGIN
		--Inserto Valoracion
		INSERT INTO public.w_valoracion (nroorden, tipo, centro, vobservacion, idprestador)
				VALUES (vnroorden::bigint, vtipoorden::bigint, vcentroorden::bigint, vobservacion, vidprestador::bigint) RETURNING idvaloracion INTO vidvalins;
			
		--Inserto Puntajes Valoraciones
		FOREACH vvaloracion IN ARRAY arrvaloraciones LOOP		
			INSERT INTO public.w_valoraciontipopuntaje
			VALUES (vidvalins, vvaloracion->>'id', vvaloracion->>'valor');
		END LOOP;		
		
	EXCEPTION
		
		--Error de Foreign Key
		WHEN SQLSTATE '23503' THEN --Error de Foreign Key
			IF SQLERRM LIKE '%_tipodoc_%' OR SQLERRM LIKE '%_nrodoc_%' THEN -- En Usuario
				RAISE EXCEPTION 'R-003 WS_valorarprestador, Usuario inválido, inténtelo nuevamente o comuníquese con soporte.';
			ELSIF SQLERRM LIKE '%_idtipoval_%' THEN
				RAISE EXCEPTION 'R-004 WS_valorarprestador, Tipo valoración inválido, inténtelo nuevamente o comuníquese con soporte.';
			ELSE
				RAISE EXCEPTION 'R-010 WS_valorarprestador, Error al valorar la orden seleccionada, inténtelo nuevamente o comuníquese con soporte.';
			END IF;
		
		--Error restricción valor puntaje
		WHEN SQLSTATE '23514' THEN
			IF SQLERRM LIKE '%_vtppuntaje_%' THEN
				RAISE EXCEPTION 'R-005 WS_valorarprestador, Puntaje recibido inválido, debe estar en el rango (0-5), inténtelo nuevamente o comuníquese con soporte.';
			END IF;
			
		--Error Clave Duplicada
		WHEN SQLSTATE '23505' THEN			
			RAISE EXCEPTION 'R-006 WS_valorarprestador, Este prestador ya fue valorado hoy, valore otro prestador o comuníquese con soporte.';
			
		WHEN SQLSTATE '23502' THEN
			RAISE EXCEPTION 'R-007 WS_valorarprestador, Valoración Incompleta, revise sus parámetros. %', string_agg(trim(array_to_string(arrvaloraciones, ','), '"'), ', ');
					
		WHEN OTHERS THEN
				RAISE EXCEPTION 'R-002 WS_valorarprestador, Error al registrar su valoración! Código %. Intente nuevamente o comuníquese con soporte. INFO: %', SQLSTATE, SQLERRM;
	END;
	
	respuestajson = concat('{ "res" : "true" ,"mensaje" : "Valoración Registrada." }');
	
	RETURN respuestajson;
END;
$function$
