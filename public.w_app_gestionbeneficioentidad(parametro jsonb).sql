CREATE OR REPLACE FUNCTION public.w_app_gestionbeneficioentidad(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
*{"accion":"obtener"}
*{"accion":"nuevo", "benombre": "Carlos Isla","bedescripcion": "Tenemos todo para construir", "becuit": "11-111111-1", "idbeneficioentidadrubro": 1}
*{"accion":"editar", "benombre": "Carlos Isla","bedescripcion": "Tenemos todo para construir", "becuit": "11-111111-1",  "idbeneficioentidadrubro": 1, "idbeneficioentidad": 1}
*{"accion":"baja", "idbeneficioentidad": "1"}
*/
DECLARE
    --RECORD
	rbeneficioentidad RECORD;
	rrespuesta RECORD;
	--VARIABLES
	respuestajson_obe jsonb;
	respuestajson jsonb;
	vfechainivigencia TIMESTAMP WITHOUT TIME ZONE;
	vfechafinvigencia TIMESTAMP WITHOUT TIME ZONE;
	idbeneficioinsert integer;
	vcodigo character varying;
	vaccion varchar;
	vcambios integer = 0;
BEGIN
    --! ELIMINAR w_app_obtenerbeneficioentidad
	IF (parametro ->> 'accion') IS NULL THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;
	vaccion = parametro->>'accion';
	CASE vaccion
		WHEN 'obtener'
			THEN
				SELECT INTO respuestajson_obe w_app_datosgestionbeneficio(parametro);
		WHEN 'nuevo'
			THEN
				IF nullvalue(parametro->>'bedescripcion') OR nullvalue(parametro->>'benombre') OR nullvalue(parametro->>'becuit') OR nullvalue(parametro->>'idbeneficioentidadrubro') THEN
					RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;


				--Inserto el nuevo beneficio
				INSERT INTO w_beneficioentidad (bedescripcion,	benombre, becuit, idbeneficioentidadrubro) VALUES
				(parametro->>'bedescripcion', parametro->>'benombre', parametro->>'becuit', CAST(parametro->>'idbeneficioentidadrubro' AS INTEGER))
                RETURNING idbeneficioentidad INTO idbeneficioinsert;

                vcodigo = MD5(CONCAT(idbeneficioinsert, CAST(now() AS TEXT)));

                UPDATE w_beneficioentidad SET becodigo = vcodigo WHERE idbeneficioentidad = idbeneficioinsert;

				--Busco datos actualizados
				SELECT INTO respuestajson_obe w_app_datosgestionbeneficio(parametro);
		WHEN 'editar'
			THEN
				IF nullvalue(parametro->>'bedescripcion') OR nullvalue(parametro->>'becuit') OR nullvalue(parametro->>'benombre') OR nullvalue(parametro->>'idbeneficioentidad') OR nullvalue(parametro->>'idbeneficioentidadrubro') THEN
					RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;
				--Actualizo la entidad
				UPDATE w_beneficioentidad
				SET bedescripcion = parametro->>'bedescripcion',
					benombre = parametro->>'benombre',
					becuit = parametro->>'becuit',
					idbeneficioentidadrubro = CAST(parametro->>'idbeneficioentidadrubro' AS INTEGER),
                    bebaja = CAST(parametro->>'bebaja' AS TIMESTAMP WITHOUT TIME ZONE)
				WHERE idbeneficioentidad = parametro->>'idbeneficioentidad';
				--Verifico si se realizo el update
				GET DIAGNOSTICS vcambios = ROW_COUNT;
				--Busco datos actualizados
				IF vcambios > 0 THEN
					SELECT INTO respuestajson_obe w_app_datosgestionbeneficio(parametro);
				ELSE
					RAISE EXCEPTION 'R-003, No se pudo realizar la actualización del beneficio, intente nuevamente.';
				END IF;
		WHEN 'baja'
			THEN
				IF nullvalue(parametro->>'idbeneficioentidad') THEN
					RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;
				--baja de la entidad
				UPDATE w_beneficioentidad
				SET bebaja = now()
				WHERE idbeneficioentidad = parametro->>'idbeneficioentidad';
				--Verifico si se realizo el update
				GET DIAGNOSTICS vcambios = ROW_COUNT;
				--Busco datos actualizados
				IF vcambios > 0 THEN
					SELECT INTO respuestajson_obe w_app_datosgestionbeneficio(parametro);
				ELSE
					RAISE EXCEPTION 'R-004, No se pudo realizar la baja del beneficio, intente nuevamente.';
				END IF;
		ELSE
	END CASE;
		--Verifico si encontre datos
	IF respuestajson_obe IS NOT NULL THEN
		respuestajson = respuestajson_obe;
	END IF;
	RETURN respuestajson;
END;
$function$
