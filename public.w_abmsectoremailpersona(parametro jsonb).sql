CREATE OR REPLACE FUNCTION public.w_abmsectoremailpersona(parametro jsonb)
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
               IF nullvalue(parametro->>'idpersona') OR nullvalue(parametro->>'idemailsector') THEN
                    RAISE EXCEPTION 'R-002 Todos los parametros deben estar completos.  %',parametro;
                END IF;

                SELECT INTO rdatos * FROM ca.emailsectorempleado WHERE idpersona = parametro->>'idpersona' AND idemailsector = parametro->>'idemailsector';

                IF NOT FOUND THEN
                    INSERT INTO ca.emailsectorempleado (idpersona, idemailsector)
                    VALUES (CAST(parametro->>'idpersona' AS BIGINT), CAST(parametro->>'idemailsector' AS BIGINT));
                ELSE
                    RAISE EXCEPTION 'R-003, El email ya se encuentra asignado al empleado.  %',parametro;
                END IF;
        WHEN 'eliminar'
            THEN
                IF nullvalue(parametro->>'idemailsectorempleado')  THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE ca.emailsectorempleado
                SET esefechafin = now()
                WHERE idemailsectorempleado = parametro->>'idemailsectorempleado';
        WHEN 'obtenersectores'
            THEN
                SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                    FROM ca.sector
                    WHERE sbaja IS NULL
                ) as t;
        WHEN 'obteneremail'
            THEN
                SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                    FROM ca.emailsector
                    WHERE nullvalue(esbaja)
                ) as t;
        ELSE
	END CASE;

    IF respuestajson_info IS NULL THEN
        SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT *
                    FROM ca.emailsector
                    NATURAL JOIN ca.sector
                    NATURAL JOIN ca.emailsectorempleado
                    NATURAL JOIN ca.persona
                    WHERE nullvalue(esbaja) AND nullvalue(esefechafin)
                    ORDER BY esefechaini DESC
        ) as t;
    END IF;

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
