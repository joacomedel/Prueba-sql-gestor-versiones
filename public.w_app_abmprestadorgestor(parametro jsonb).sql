CREATE OR REPLACE FUNCTION public.w_app_abmprestadorgestor(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$-- SELECT w_app_abmprestadorgestor('{"pcuit":"20-28718951-7", "idusuariowebgestor":"26269"}')
DECLARE
    --RECORD
	rdatos RECORD;
	--VARIABLES
	respuestajson_info jsonb; 
	respuestajson jsonb;
	vaccion varchar; 
	vidprestador BIGINT;
	vidusuariowebgestor BIGINT;

BEGIN
	IF ((parametro ->> 'accion') IS NULL OR (parametro ->> 'pcuit') IS NULL OR (parametro ->> 'idusuariowebgestor') IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	vaccion = parametro->>'accion';
	vidusuariowebgestor = CAST(parametro->>'idusuariowebgestor' AS BIGINT);

	-- Busco si el prestador esta asociado a SOSUNC
	SELECT INTO vidprestador w_app_buscaridprestador(parametro);


	IF FOUND THEN
		CASE vaccion 
		WHEN 'vincular' THEN 

            --Verifico que sea prestador y que no sea el mismo
            --SL 18/03/2024 - Cambio consulta por forma correcta de verificar con nueva implementacion de gestorPrestador
            SELECT INTO rdatos * FROM prestador
                LEFT JOIN w_usuarioprestador AS usp USING(idprestador)
                LEFT JOIN w_usuarioweb USING(idusuarioweb)
                LEFT JOIN w_usuariorolweb USING(idusuarioweb)
            WHERE idprestador = vidprestador 
                AND (nullvalue(usp.idusuarioweb) OR usp.idusuarioweb <> vidusuariowebgestor)
                AND (nullvalue(idrolweb) OR idrolweb = 2 OR idrolweb = 15);

            IF FOUND THEN
                --Verifico que no este vinculado 
                SELECT INTO rdatos * FROM w_usuariowebgestorprestador
                WHERE idusuarioweb = vidusuariowebgestor
                AND idprestador = vidprestador AND nullvalue(gupeliminado);

                IF NOT FOUND THEN
                    --Inserto el prestador con el gestor
                    INSERT INTO w_usuariowebgestorprestador (idusuarioweb, idprestador) VALUES (vidusuariowebgestor, vidprestador);
                ELSE
					RAISE EXCEPTION 'R-008, El prestador ya se encuentra vinculado';
                END IF;
            ELSE
                RAISE EXCEPTION 'R-009, El CUIT ingresado no es de un prestador valido. (%)', parametro ->> 'pcuit';
            END IF;
			
		WHEN 'desvincular' THEN 

			--Verifico que este vinculado 
			SELECT INTO rdatos * FROM w_usuariowebgestorprestador
			WHERE idusuarioweb = vidusuariowebgestor 
			AND idprestador = vidprestador
			AND nullvalue(gupeliminado);

			IF FOUND THEN
				--Elimino el prestador con el gestor
				UPDATE w_usuariowebgestorprestador 
					SET gupeliminado = now() 
				WHERE idusuarioweb = vidusuariowebgestor 
					AND idprestador = vidprestador
					AND nullvalue(gupeliminado);
			ELSE
				RAISE EXCEPTION 'R-006, El prestador no se encuentra vinculado';
			END IF;
		WHEN 'buscar' THEN 

			--Verifico que este vinculado 
			SELECT INTO rdatos * FROM prestador
			WHERE idprestador = vidprestador;

			IF FOUND THEN
				respuestajson_info = row_to_json(rdatos);
				respuestajson = respuestajson_info;
			ELSE
				RAISE EXCEPTION 'R-007, El prestador no se encuentra asociado a SOSUNC o el CUIT es incorrecto';
			END IF;
		END CASE;

		IF respuestajson IS NULL THEN
			--Busco todos los prestadores del gestor
			SELECT INTO respuestajson_info w_app_buscarprestadoresgestor(jsonb_build_object('idusuarioweb', vidusuariowebgestor));
			IF FOUND THEN
				respuestajson = respuestajson_info;
			ELSE
				RAISE EXCEPTION 'R-007, No se pudo vincular el prestador';
			END IF;
		END IF;
	ELSE
		RAISE EXCEPTION 'R-002, El prestador no se encuentra asociado a SOSUNC o el CUIT es incorrecto';
	END IF;

	RETURN respuestajson;
END;

$function$
