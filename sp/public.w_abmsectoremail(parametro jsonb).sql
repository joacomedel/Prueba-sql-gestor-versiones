CREATE OR REPLACE FUNCTION public.w_abmsectoremail(parametro jsonb)
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
               IF nullvalue(parametro->>'email') OR nullvalue(parametro->>'idsector') THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                INSERT INTO ca.emailsector (email,idsector)
                VALUES (parametro->>'email', CAST(parametro->>'idsector' AS BIGINT));

        WHEN 'eliminar'
            THEN
                IF nullvalue(parametro->>'idemailsector') THEN
                    RAISE EXCEPTION 'R-006, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE ca.emailsector
                SET esbaja = now()
                WHERE idemailsector = parametro->>'idemailsector';
        WHEN 'obtenersectores'
            THEN
                SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                    FROM ca.sector
                    WHERE sbaja IS NULL
                ) as t;
        WHEN 'obteneremailpersona'
            THEN
                SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                    FROM ca.emailsector
                    NATURAL JOIN ca.sector
                    NATURAL JOIN ca.emailsectorempleado
                    NATURAL JOIN ca.persona
                    WHERE nullvalue(esbaja) AND nullvalue(esefechafin)
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
        -- SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        -- FROM (
        --     SELECT 
        --         CONCAT(       
        --                 ememail,        
        --                     CASE WHEN STRING_AGG(email, '-') IS NOT NULL THEN        
        --                 CONCAT('-',STRING_AGG(email, '-'))        
        --                     ELSE ''        
        --                 END    
        --             ) AS emails
        --     FROM ca.emailsectorempleado
        --         NATURAL JOIN ca.emailsector
        --         NATURAL JOIN ca.empleado
        --         NATURAL JOIN ca.persona
        --         NATURAL JOIN ca.sector
        --     WHERE esbaja IS NULL
        --     GROUP BY ememail, idpersona, idsector
        SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT *
            FROM ca.emailsector
            NATURAL JOIN ca.sector
            WHERE esbaja IS NULL
        ) as t;
    END IF;

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
