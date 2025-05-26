CREATE OR REPLACE FUNCTION public.w_abmsectortelefonopersona(parametro jsonb)
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
                IF nullvalue(parametro->>'idpersona') OR nullvalue(parametro->>'idtelefonosector') THEN
                    RAISE EXCEPTION 'R-002 Todos los parametros deben estar completos.  %',parametro;
                END IF;

                SELECT INTO rdatos * FROM ca.telefonosectorpersona WHERE idpersona = parametro->>'idpersona' AND idtelefonosector = parametro->>'idtelefonosector';

                IF NOT FOUND THEN
                    INSERT INTO ca.telefonosectorpersona (idpersona, idtelefonosector)
                    VALUES (CAST(parametro->>'idpersona' AS BIGINT), CAST(parametro->>'idtelefonosector' AS BIGINT));
                ELSE
                    RAISE EXCEPTION 'R-003, El telefono ya se encuentra asignado al empleado.  %',parametro;
                END IF;
        WHEN 'eliminar' 
            THEN
                IF nullvalue(parametro->>'idtelefonosector')  THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE ca.telefonosectorpersona
                SET tpsfechafin = now()
                WHERE idtelefonosector = parametro->>'idtelefonosector';
        ELSE
	END CASE;

    IF respuestajson_info IS NULL THEN
        SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT *
                    FROM ca.telefonosector
                    NATURAL JOIN ca.sector
                    NATURAL JOIN ca.telefonotipo
                    NATURAL JOIN ca.telefonosectorpersona
                    NATURAL JOIN ca.persona
                    WHERE nullvalue(tsbaja) AND nullvalue(tpsfechafin)
                    ORDER BY tpsfechaini DESC
        ) as t;
    END IF;

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
