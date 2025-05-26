CREATE OR REPLACE FUNCTION public.w_app_gestionbeneficioentidadrubro(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
*{"accion":"obtener"}
*{"accion":"nuevo", "berdescripcion": "Construccion","berorden": 1}
*{"accion":"editar", "berdescripcion": "Construccion","berorden": 1, "idbeneficioentidadrubro": 1}
*{"accion":"baja", "idbeneficioentidadrubro": 1}
*/
DECLARE
    --RECORD
	rbeneficioentidad RECORD;
	rrespuesta RECORD;
	--VARIABLES
	respuestajson_ober jsonb;
	respuestajson jsonb;
	vfechainivigencia TIMESTAMP WITHOUT TIME ZONE;
	vfechafinvigencia TIMESTAMP WITHOUT TIME ZONE;
	vaccion varchar;
	vcambios integer = 0;
BEGIN
	IF (parametro ->> 'accion') IS NULL THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;
	vaccion = parametro->>'accion';
	CASE vaccion
		WHEN 'obtener'
			THEN
                SELECT INTO respuestajson_ober w_app_datosgestionbeneficio(parametro);
		WHEN 'nuevo'
			THEN
				IF nullvalue(parametro->>'berdescripcion') OR nullvalue(parametro->>'berorden') THEN
					RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;
				--Inserto el nuevo beneficio
				INSERT INTO w_beneficioentidadrubro (berdescripcion, berorden) VALUES
				(parametro->>'berdescripcion', CAST(parametro->>'berorden' AS INTEGER));
				--Busco datos actualizados
                SELECT INTO respuestajson_ober w_app_datosgestionbeneficio(parametro);
		WHEN 'editar'
			THEN
				IF nullvalue(parametro->>'berdescripcion') OR nullvalue(parametro->>'berorden')  OR nullvalue(parametro->>'idbeneficioentidadrubro') THEN
					RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;
				--Actualizo la entidad
				UPDATE w_beneficioentidadrubro
				SET berdescripcion = parametro->>'berdescripcion',
					berorden = CAST(parametro->>'berorden' AS INTEGER),
                    berbaja = CAST(parametro->>'berbaja' AS TIMESTAMP WITHOUT TIME ZONE),
                    berfechamodificacion = now()
				WHERE idbeneficioentidadrubro = parametro->>'idbeneficioentidadrubro';
				--Verifico si se realizo el update
				GET DIAGNOSTICS vcambios = ROW_COUNT;
				--Busco datos actualizados
				IF vcambios > 0 THEN
                    SELECT INTO respuestajson_ober w_app_datosgestionbeneficio(parametro);
				ELSE
					RAISE EXCEPTION 'R-003, No se pudo realizar la actualización del beneficio, intente nuevamente.';
				END IF;
		WHEN 'baja'
			THEN
				IF nullvalue(parametro->>'idbeneficioentidadrubro') THEN
					RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;
				--baja de la entidad
				UPDATE w_beneficioentidadrubro
				SET berbaja	= now()
				WHERE idbeneficioentidadrubro = parametro->>'idbeneficioentidadrubro';
				--Verifico si se realizo el update
				GET DIAGNOSTICS vcambios = ROW_COUNT;
				--Busco datos actualizados
				IF vcambios > 0 THEN
                     SELECT INTO respuestajson_ober w_app_datosgestionbeneficio(parametro);
				ELSE
					RAISE EXCEPTION 'R-004, No se pudo realizar la baja del beneficio, intente nuevamente.';
				END IF;
		ELSE
	END CASE;
		--Verifico si encontre datos
	IF respuestajson_ober IS NOT NULL THEN
		respuestajson = respuestajson_ober;
	END IF;
	RETURN respuestajson;
END;
$function$
