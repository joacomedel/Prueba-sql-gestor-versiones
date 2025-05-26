CREATE OR REPLACE FUNCTION public.w_abmcalendario(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idusuarioweb": 5538, "accion": "obtener", "idtipocalendario": 1}
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
    IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'accion') THEN
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    vaccion = parametro->>'accion';
    CASE vaccion
         WHEN 'cargamasiva'
            THEN
                IF nullvalue(parametro->>'arrayDias') THEN
                    RAISE EXCEPTION 'R-002, Todos los parametros deben estar completos.  %',parametro;
                END IF;
                IF jsonb_typeof(parametro->'arrayDias') != 'array' THEN
                    RAISE EXCEPTION 'R-005, El parámetro arrayDias debe ser un array JSON válido';
                END IF;
                    arrayDias := ARRAY(SELECT jsonb_array_elements(parametro->'arrayDias'));
                RAISE NOTICE 'arrayOrd: %', arrayDias;
                FOREACH paramDia IN ARRAY arrayDias
                LOOP
                    -- --Inserto en la tabla calendario
                    -- INSERT INTO ca.calendario (idusuarioweb, cldescripcion, clfecha, clmovible, idtipocalendario)
                    -- VALUES (CAST(parametro->>'idusuarioweb' AS BIGINT), paramDia->>'nombre', CAST(paramDia->>'fecha' AS DATE),
                    -- CASE 
                    --     WHEN paramDia->>'tipo' = 'trasladable' THEN true 
                    --     ELSE false 
                    -- END, 1);

                    --Inserto en la tabla feriado
                    INSERT INTO ca.feriado (fefecha, fedescripcion, idferiadotipo)
                    VALUES (CAST(paramDia->>'fecha' AS DATE), paramDia->>'nombre',2);
                END LOOP;
        WHEN 'obtenertipoycentro'
            THEN
                SELECT INTO respuestajson_tipo array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                    FROM ca.feriadotipo
                ) as t;

                SELECT INTO respuestajson_centro array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                    FROM centroregional
                ) as t;

                respuestajson_info = jsonb_build_object('tipos', COALESCE(respuestajson_tipo, '{}'::jsonb), 'centros', COALESCE(respuestajson_centro, '{}'::jsonb)); 
        WHEN 'nuevo'
            THEN
               IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'fedescripcion') OR nullvalue(parametro->>'fefecha')  
               OR nullvalue(parametro->>'idferiadotipo') THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                INSERT INTO ca.feriado (fefecha, fedescripcion,	idferiadotipo,	idcentroregional)
                VALUES (CAST(parametro->>'fefecha' AS DATE), parametro->>'fedescripcion',
                CAST(parametro->>'idferiadotipo' AS BIGINT), CAST(parametro->>'idcentroregional' AS BIGINT));
        WHEN 'modificar'
            THEN
                IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'fedescripcion') OR nullvalue(parametro->>'fefecha') 
                OR nullvalue(parametro->>'idferiado')  OR nullvalue(parametro->>'idferiadotipo') THEN
                    RAISE EXCEPTION 'R-003, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE ca.feriado
                SET fefecha = CAST(parametro->>'fefecha' AS DATE),
                    fedescripcion = parametro->>'fedescripcion',
                    idcentroregional = CAST(parametro->>'idcentroregional' AS BIGINT),
                    idferiadotipo = CAST(parametro->>'idferiadotipo' AS BIGINT)
                WHERE idferiado = parametro->>'idferiado';
        WHEN 'eliminar'
            THEN
                IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'idferiado') THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE ca.feriado
                SET febaja = now()
                WHERE idferiado = parametro->>'idferiado';
        ELSE
	END CASE;

    IF respuestajson_info IS NULL THEN
        SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT *
            FROM ca.feriado
            NATURAL JOIN ca.feriadotipo
            LEFT JOIN centroregional USING (idcentroregional)
            where nullvalue(febaja) 
            AND (CASE WHEN NOT nullvalue(parametro->>'idferiadotipo') THEN idferiadotipo = parametro->>'idferiadotipo' ELSE true END)
            AND EXTRACT(YEAR FROM fefecha) = EXTRACT(YEAR FROM CURRENT_DATE)
        ) as t;
    END IF;

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
