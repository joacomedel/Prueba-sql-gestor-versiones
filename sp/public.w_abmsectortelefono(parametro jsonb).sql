CREATE OR REPLACE FUNCTION public.w_abmsectortelefono(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"accion": "obtener"}
*/
DECLARE
    respuestajson_info jsonb;
    respuestajson_tipo jsonb;
    respuestajson_centro jsonb;
    respuestajson jsonb;
    vaccion character varying;
    rdatos RECORD;
    arrayDias jsonb[];
    paramDia jsonb;
begin
    IF nullvalue(parametro->>'accion') THEN
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    vaccion = parametro->>'accion';
    CASE vaccion
        WHEN 'nuevo'
            THEN
               IF nullvalue(parametro->>'telefono') OR nullvalue(parametro->>'idsector') OR nullvalue(parametro->>'idtelefonotipo') THEN
                    RAISE EXCEPTION 'R-002 Todos los parametros deben estar completos.  %',parametro;
                END IF;

                SELECT INTO rdatos * FROM ca.telefonosector WHERE tstelefono = parametro->>'telefono' AND idsector = parametro->>'idsector' AND idtelefonotipo = parametro->>'idtelefonotipo';

                IF NOT FOUND THEN
                    INSERT INTO ca.telefonosector (tstelefono, idsector, idtelefonotipo)
                    VALUES (CAST(parametro->>'telefono' AS BIGINT), CAST(parametro->>'idsector' AS BIGINT), CAST(parametro->>'idtelefonotipo' AS BIGINT));
                ELSE
                    RAISE EXCEPTION 'R-003, El telefono ya se encuentra asignado al empleado.  %',parametro;
                END IF;
        WHEN 'eliminar'
            THEN
                IF nullvalue(parametro->>'idtelefonosector')  THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE ca.telefonosector
                SET tsbaja = now()
                WHERE idtelefonosector = parametro->>'idtelefonosector';
        WHEN 'obtenertipotelefono'
            THEN
                SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                    FROM ca.telefonotipo
                ) as t;
        WHEN 'obtenertelefono'
            THEN
                SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                    FROM ca.telefonosector
                    WHERE nullvalue(tsbaja)
                ) as t;
        ELSE
	END CASE;

    IF respuestajson_info IS NULL THEN
        SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT *
                    FROM ca.telefonosector
                    NATURAL JOIN ca.sector
                    NATURAL JOIN ca.telefonotipo
                    WHERE nullvalue(tsbaja) 
        ) as t;
    END IF;

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
