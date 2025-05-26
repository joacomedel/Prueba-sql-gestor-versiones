CREATE OR REPLACE FUNCTION public.w_abmturno(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"NroDocumento":"08216252","TipoDocumento":1}
*/
DECLARE
--VARIABLES 
   vmontoctacte DOUBLE PRECISION;
   vaccion varchar;
   varchivos varchar;
   
   vidturno varchar;
   vidcentroturno varchar;   
   vidrolweb varchar;
   vidturnotipo varchar;
   vidusuarioweb varchar;
   vnrodoc varchar;
   vtipodoc varchar;
    item JSONB;
--RECORD
      respuestajson jsonb;
	  lista_turnos jsonb;
      rpersona RECORD;
      rafiliado  RECORD;
      rformapagouw RECORD;
      datosarchivo RECORD;
      rresp RECORD;
      elidturno bigint;
      elidcentroturno  integer;
      rturno  record;
      restado  record;
      restado_anterior  record;

---idturno
BEGIN
	elidturno = parametro->>'idturno';
	elidcentroturno  = parametro->>'idcentroturno';
	vaccion = parametro ->>'w_turno_accion';
    varchivos = parametro ->>'archivos';
	
	IF (vaccion = 'nuevo') THEN
	
		-- verifico que no exista un turno en atención del mismo tipo
		/* 
		SELECT INTO rresp concat (idturno,'|', idcentroturno)as turnoactual, *
			FROM w_turno
			NATURAL JOIN w_turnoestado
			NATURAL JOIN w_turnoestadotipo
			WHERE idturnotipo = (parametro->>'idturnotipo')::INTEGER
				AND tipodoc=(parametro->>'tipodoc')::SMALLINT
				AND nrodoc=parametro->>'nrodoc'
				AND nullvalue(tefechafin) AND not(teteditable);
		IF NOT FOUND THEN
		*/
			--
			INSERT INTO w_turno (idturnotipo,tipodoc,nrodoc,tuobservacion,tucontacto)
				VALUES ((parametro->>'idturnotipo')::INTEGER, (parametro->>'tipodoc')::SMALLINT, parametro->>'nrodoc',concat('[',to_char(current_timestamp,'DD-MM-YYYY HH24:MI:SS'),']', chr(10), parametro->>'tuobservacion_nueva'),parametro->>'tucontacto');
				elidturno = currval('public.w_turno_idturno_seq');
				elidcentroturno = centro();
				
			INSERT INTO w_turnoestado (idturno,idusuarioweb,idcentroturno,idturnoestadotipo, tecomentarioexterno)
				VALUES (elidturno, (parametro->>'idusuarioweb')::INTEGER, elidcentroturno, (parametro->>'idturnoestadotipo')::BIGINT , concat('[',to_char(current_timestamp,'DD-MM-YYYY HH24:MI:SS'),']', chr(10), parametro->>'tuobservacion_nueva')) ;
		
			parametro = parametro || jsonb_build_object('idturno', elidturno, 'idcentroturno', elidcentroturno);
		/*
		ELSE
			RAISE EXCEPTION 'R-001, Ya cuenta con un turno activo.  %',turnoactual;  
		END IF;
		*/
	END IF;



    IF (vaccion = 'editar') THEN 
    
        -- RAISE EXCEPTION 'R-003 fijandome en esto, probando %',parametro;
		
        vidturno = parametro->>'idturno';
		vidcentroturno = parametro->>'idcentroturno';
		
		IF vidturno IS NULL OR vidcentroturno IS NULL THEN
			RAISE EXCEPTION 'R-003 abmturno-editar: parametros inválidos. Parámetros: %',parametro;
		END IF;	
	
		UPDATE w_turno 
			SET tucontacto = (parametro->>'tucontacto'), tuobservacion = concat('[',to_char(current_timestamp,'DD-MM-YYYY HH24:MI:SS'),']', ' ', parametro->>'tuobservacion_nueva', chr(10), parametro->>'tuobservacion' )
			WHERE idturno = vidturno
				AND idcentroturno = vidcentroturno; --AND idcentroregional = (parametro->>'idcentroregional'); 
	
				
		-- busco el estado actual del turno que esta modificando el AFILLIADO
		SELECT INTO restado *
			FROM w_turnoestado
			WHERE nullvalue(tefechafin) AND idturno = vidturno 
				AND idcentroturno = vidcentroturno;
                --SL 04/04/24 - Agrego tipo 38 para reintegros
		IF (restado.idturnoestadotipo = 11 or restado.idturnoestadotipo = 14 or restado.idturnoestadotipo = 18 or restado.idturnoestadotipo = 26  or restado.idturnoestadotipo = 29 or restado.idturnoestadotipo = 38) THEN  
			-- Si se esta esperando respuesta afiliado y se esta modificando se debe volver al estado anterior
			
			--ds 09/04/25 comento este porque me traia mal el ultimo estado
			-- SELECT INTO restado_anterior *
			-- 	FROM w_turnoestado
			-- 	WHERE tefechafin = restado.tefechaini AND idturno = vidturno
			-- 		AND idcentroturno = vidcentroturno;

			--ds 09/04/25 agrego este para buscar el ultimo estado que sea distinto al actual y que me traiga el ultimo
			SELECT INTO restado_anterior *
				FROM w_turnoestado
				WHERE tefechafin IS NOT NULL AND idturno = vidturno
					AND idcentroturno = vidcentroturno AND idturnoestadotipo <> restado.idturnoestadotipo  ORDER BY tefechafin DESC LIMIT 1 ;
						
			UPDATE w_turnoestado
				SET tefechafin = CURRENT_TIMESTAMP
				WHERE nullvalue(tefechafin) AND idturno = vidturno
					AND idcentroturno = vidcentroturno;

			--ds agrego esto para poder ver las respuestas completas 26-02-2025
			INSERT INTO w_turnoestado (idturno,idusuarioweb,idcentroturno,idturnoestadotipo ,tecomentarioexterno) 
				VALUES (vidturno::BIGINT, CAST(parametro->>'idusuarioweb' AS INTEGER), vidcentroturno::SMALLINT, restado_anterior.idturnoestadotipo, parametro->>'tuobservacion_nueva');

		ELSE 


		IF (restado.idusuarioweb = parametro->>'idusuarioweb' ) THEN 
			--ds agrego esto para poder ver las respuestas completas 26-02-2025
		UPDATE w_turnoestado
		SET tecomentarioexterno = CASE
			WHEN tecomentarioexterno IS NULL OR tecomentarioexterno = '' THEN 
				concat('[', to_char(current_timestamp, 'DD-MM-YYYY HH24:MI:SS'), ']', '', parametro->>'tuobservacion_nueva')
			ELSE 
				 concat('[',to_char(current_timestamp,'DD-MM-YYYY HH24:MI:SS'),']', ' ', parametro->>'tuobservacion_nueva', chr(10), tecomentarioexterno )
			END
		WHERE nullvalue(tefechafin) 
		AND idturno = vidturno
		AND idcentroturno = vidcentroturno;

		-- UPDATE w_turnoestado
		-- SET tecomentarioexterno = concat('[', to_char(current_timestamp, 'DD-MM-YYYY HH24:MI:SS'), ']', '', parametro->>'tuobservacion_nueva')
		-- WHERE nullvalue(tefechafin) 
		-- AND idturno = vidturno
		-- AND idcentroturno = vidcentroturno;

		ELSE 

			UPDATE w_turnoestado
				SET tefechafin = CURRENT_TIMESTAMP
				WHERE idturnoestado = restado.idturnoestado;

		-- raise exception 'R-002 abmturno-listar: parametros inválidos. Parámetros: %',parametro->>'idusuarioweb';

		INSERT INTO w_turnoestado (idturno,idusuarioweb,idcentroturno,idturnoestadotipo ,tecomentarioexterno) 
		VALUES (vidturno::BIGINT, (parametro->>'idusuarioweb')::INTEGER, vidcentroturno::SMALLINT, restado.idturnoestadotipo, concat('[',to_char(current_timestamp,'DD-MM-YYYY HH24:MI:SS'),']', chr(10), parametro->>'tuobservacion_nueva'));

		END IF;
		END IF;


		
	END IF;
				
	-- ASGINO EL TURNO A UN EMPLEADO
	IF (vaccion = 'atender') THEN

			--RAISE EXCEPTION 'R-002 abmturno-listar: parametros inválidos. Parámetros: %',parametro->>'turnosatender';

		-- UPDATE w_turnoestado
		-- 	SET tefechafin = CURRENT_TIMESTAMP
		-- 	WHERE idturnoestado = (parametro->>'idturnoestado') AND 
		-- 		idcentroturnoestado = (parametro->>'idcentroturnoestado') ;

		-- INSERT INTO w_turnoestado (idturno,idusuarioweb,idcentroturno,idturnoestadotipo) -- ,tecomentarioexterno) 
		-- 	VALUES ((parametro->>'idturno')::BIGINT, (parametro->>'idusuarioweb')::INTEGER, (parametro->>'idcentroturno')::SMALLINT, (parametro->>'idturnoestadotipo')::SMALLINT);

		---
		 FOR item IN SELECT * FROM jsonb_array_elements(parametro->'turnosatender') LOOP
			-- Ejecutar la consulta UPDATE
			UPDATE w_turnoestado
			SET tefechafin = CURRENT_TIMESTAMP
			WHERE idturnoestado = (item->>'idturnoestado')::BIGINT
			AND idcentroturnoestado = (item->>'idcentroturnoestado')::SMALLINT;

			-- Ejecutar la consulta INSERT
			INSERT INTO w_turnoestado (idturno, idusuarioweb, idcentroturno, idturnoestadotipo)
			VALUES (
				(item->>'idturno')::BIGINT,
				(parametro->>'idusuarioweb')::INTEGER,
				(item->>'idcentroturno')::SMALLINT,
				(parametro->>'idturnoestadotipo')::SMALLINT);

		vaccion = 'obtenerturnoestado';
		

    END LOOP;

	END IF;

	---2346

	IF (vaccion = 'cambiar_estado') THEN
		UPDATE w_turnoestado
		SET tefechafin = CURRENT_TIMESTAMP
			WHERE idturno = (parametro->>'idturno') AND idcentroturno = (parametro->>'idcentroturno')
				AND nullvalue(tefechafin);

		-- RAISE EXCEPTION 'R-002 abmturno-listar: parametros inválidos. Parámetros: %',parametro->>'tecomentarioexterno';

		INSERT INTO w_turnoestado (idturno,idusuarioweb,idcentroturno,idturnoestadotipo, tecomentarioexterno,tecomentariointerno,teresaltar, tefechavencimiento) 
			VALUES ((parametro->>'idturno')::BIGINT, 
				(parametro->>'idusuarioweb')::INTEGER, 
				(parametro->>'idcentroturno')::SMALLINT,
				(parametro->>'idturnoestadotipo')::SMALLINT,
				(parametro->>'tecomentarioexterno'),
				(parametro->>'tecomentariointerno'),
				(parametro->>'teresaltar')::INTEGER,
				(parametro->>'tefechavencimiento')::TIMESTAMP );

		
/*
		SELECT INTO rafiliado ua.idusuarioweb, ua.nrodoc, ua.tipodoc, tt.tetnombre
			FROM w_turno t
            NATURAL JOIN w_turnoestado te
            NATURAL JOIN w_turnoestadotipo tt
            JOIN w_usuarioafiliado ua USING (nrodoc, tipodoc) 
        WHERE idturno = (parametro->>'idturno') AND idcentroturno = (parametro->>'idcentroturno') AND nullvalue(tefechafin);
*/
-- SL 17/01/25 - Busco el id en usuarioafiliado o usuariorolwebsiges ya que hay usuarios que son empleados que no estan en usuarioafiliado

		SELECT INTO rafiliado CASE WHEN nullvalue(ua.idusuarioweb) THEN  urws.idusuarioweb ELSE ua.idusuarioweb END AS idusuarioweb, p.nrodoc, p.tipodoc, tt.tetnombre
			FROM w_turno t
            NATURAL JOIN w_turnoestado te
            NATURAL JOIN w_turnoestadotipo tt
            LEFT JOIN w_usuarioafiliado ua USING (nrodoc, tipodoc) 
            LEFT JOIN w_usuariorolwebsiges urws ON (urws.idrolweb = 1 AND urws.dni = nrodoc)
            JOIN persona AS p ON (p.nrodoc = CASE WHEN nullvalue(ua.nrodoc) THEN urws.dni ELSE ua.nrodoc END )
        WHERE idturno = (parametro->>'idturno') AND idcentroturno = (parametro->>'idcentroturno') AND nullvalue(tefechafin);

        --SL 17/01/25 - Agregp excepcion si no lo encuentra al afiliado
        IF NOT FOUND THEN
           RAISE EXCEPTION 'R-158: Ha ocurrido un error durante la modificación del reintegro. Por favor, comuníquese a soporte.app@sosunc.net.ar y proporcione el código de error';
        END IF;

        -- SL 03/10/24 - Notificamos cuando se encuentra en los estados "Esperando respuesta Afiliado", "Finalizada"
        -- IF FOUND AND parametro->>'idturnoestadotipo' = 38 OR parametro->>'idturnoestadotipo' = 36  THEN
        --     PERFORM w_enviarNotificacionPush(jsonb_build_object(
        --         'idusuarioweb', rafiliado.idusuarioweb,
        --         'tag', 'tag',
        --         'mensaje', 'Te informamos que tu reintegro N° ' || COALESCE(parametro->>'idturno', '') || '-' || COALESCE(parametro->>'idcentroturno', '') || ' Se encuentra en estado ' || rafiliado.tetnombre,
        --         'link', 'reintegros',
        --         'sensible', false, 
        --         'interno', true
        --         ));
        -- END IF;

		IF (parametro->>'uwnombre' = 'ususm') THEN
			vaccion = 'obtenerturnoestado';
		END IF;

	END IF;

    --ds  
	IF (vaccion = 'obtenerturnoestado' OR vaccion = 'historial' ) THEN 
        SELECT w_obtenerturnoestado(
            parametro  ) INTO lista_turnos;
    END IF;

-- RAISE EXCEPTION 'R-002 abmturno-listar: parametros inválidos. Parámetros: %',varchivos;
	


    IF (varchivos IS NOT NULL) THEN 

		-- RAISE EXCEPTION 'R-002 abmturno-listar: parametros inválidos. Parámetros: %',parametro;

        SELECT w_guardararchivo(
                    jsonb_build_object(
                        'tipo', 'turno',
                        'archivossubidos', parametro->>'archivos',
						'archivostipo', parametro->>'archivosTipo',
                        'datosasoc', parametro
                    )
               ) INTO datosarchivo;
    END IF;
	
	IF (vaccion = 'listar' OR (parametro->>'uwnombre' = 'ususm' AND (vaccion = 'nuevo' OR vaccion = 'editar'))) THEN		
		vidrolweb = parametro ->> 'idrolweb'; --17
		vidturnotipo = parametro ->> 'idturnotipo' ; --11
		vidusuarioweb = parametro ->> 'idusuarioweb';
		vnrodoc = parametro ->> 'nrodoc';
		vtipodoc = parametro ->> 'tipodoc';

		
		IF (vnrodoc IS NULL OR vtipodoc IS NULL OR vidrolweb IS NULL OR vidturnotipo IS NULL) THEN
			RAISE EXCEPTION 'R-002 abmturno-listar: parametros inválidos. Parámetros: %',parametro->>'idrolweb';
		END IF;
		
		SELECT INTO lista_turnos json_agg(res_turnos)
			FROM (
				SELECT *, TO_CHAR(tufecha :: DATE, 'dd-mm-yyyy') AS tusfecha, concat(apellido, ', ', nombres) AS nombreafiliado,
					CASE
						WHEN (w_turnoestadotipo.teteditable) THEN (
							SELECT count(*) + 1 
								FROM w_turnoestado 
								NATURAL JOIN w_turnoestadotipo 
								WHERE nullvalue(tefechafin) AND teteditable AND idrolweb = vidrolweb AND w_turno.idturno > w_turnoestado.idturno
						)
					ELSE 0
					END AS cantespera, 
					(SELECT json_agg(arch) FROM
						(SELECT w_archivo.*, w_turnoarchivo.*, md5(concat(idarchivo::VARCHAR,w_archivo.idcentroarchivo)) AS nombrearchivo
						 	FROM w_turno AS turno
						 		JOIN w_turnoarchivo USING(idturno)
						 		JOIN w_archivo USING(idarchivo)
						 	WHERE arhabilitado AND turno.idturno = w_turno.idturno AND w_turnoarchivo.idturnoarchivotipo = 2
						) arch						
					) AS archivos
					, CASE 
						WHEN w_turno.tuobservacion LIKE '%' || w_turnoestado.tecomentarioexterno || '%' THEN null
						ELSE tecomentarioexterno
					END AS tecomentarioexterno
				FROM w_turno NATURAL JOIN persona 	
					LEFT JOIN personacentroregional ON (personacentroregional.nrodoc = w_turno.nrodoc AND personacentroregional.tipodoc = w_turno.tipodoc)
					LEFT JOIN centroregional ON (personacentroregional.idcentropersonacentroregional = centroregional.idcentroregional)
					NATURAL JOIN w_turnotipo
					JOIN w_turnoestado USING(idturno)
					JOIN w_turnoestadotipo USING(idturnoestadotipo)
				WHERE true 
					-- AND (idusuarioweb = vidusuarioweb and )
					AND w_turno.nrodoc ilike concat('%',vnrodoc,'%')
					AND w_turno.tipodoc ilike concat('%',vtipodoc,'%')
					AND nullvalue(tefechafin)
					AND w_turnotipo.idrolweb ilike concat('%',vidrolweb,'%')
					AND w_turnotipo.idturnotipo ilike concat('%',vidturnotipo,'%')
                                        AND nullvalue(w_turnoestado.tefechafin)
                                        AND w_turnoestado.idturnoestadotipo <> 41
				ORDER BY w_turno.idturno DESC
			) AS res_turnos;
	END IF;
	
	-- Para generar una excepción
	-- RAISE EXCEPTION 'R-001, Al Menos uno de los parametros deben estar completos.  %',parametro;
	-- Devolver IDs para adjuntar archivos.

	IF (vaccion != 'listar') THEN
        
        IF (parametro->>'uwnombre' = 'ususm') THEN 
            IF lista_turnos IS NOT NULL THEN
				respuestajson = concat('{"listar":',lista_turnos,'}');		
			ELSE 
				respuestajson = '{"listar":[]}';
			END IF;
        ELSE
        
        SELECT INTO rturno * FROM w_turno WHERE	idturno = elidturno  AND idcentroturno = elidcentroturno;
		respuestajson = row_to_json(rturno);
       
        END IF;

	ELSIF (vaccion = 'listar') THEN
		IF lista_turnos IS NOT NULL THEN
			respuestajson = concat('{"listar":',lista_turnos,'}');		
		ELSE 
			respuestajson = '{"listar":[]}';
		END IF;
	ELSE 
		RAISE EXCEPTION 'R-001 abmturno: parametro "w_turno_accion" inválida. w_turno_accion: %',vaccion;
	END IF;
	
	return respuestajson;

end;

$function$
