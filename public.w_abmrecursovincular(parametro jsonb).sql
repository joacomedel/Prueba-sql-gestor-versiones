CREATE OR REPLACE FUNCTION public.w_abmrecursovincular(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"accion": "obtener", "idrecursotipo": 4}
*/
DECLARE
    respuestajson jsonb;
    respuestajson_info jsonb;
    vaccion character varying;
    vidrecurso BIGINT;
    vidcentrorecurso BIGINT;
    rdatos RECORD;
    --Param para la busqueada de la tabla asincronica
    buscar TEXT;
    pagesize INTEGER;
    numpage INTEGER;
begin
    IF nullvalue(parametro->>'accion') THEN
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    vaccion = parametro->>'accion';
    CASE vaccion
        WHEN 'nuevo'
            THEN
                IF nullvalue(parametro->>'idrecurso') OR nullvalue(parametro->>'idcentrorecurso')  OR nullvalue(parametro->>'idpersona') THEN
                    RAISE EXCEPTION 'R-002 Todos los parametros deben estar completos.  %',parametro;
                END IF;

                SELECT INTO rdatos * 
                    FROM public.recursopersona 
                WHERE idrecurso = parametro->>'idrecurso' 
                    AND idpersona = parametro->>'idpersona'
                    AND idcentrorecurso = parametro->>'idcentrorecurso'
                    AND nullvalue(rpfechafin);

                IF NOT FOUND THEN
                    INSERT INTO public.recursopersona (idrecurso, idpersona, idcentrorecurso)
                    VALUES (CAST(parametro->>'idrecurso' AS BIGINT), CAST(parametro->>'idpersona' AS BIGINT), CAST(parametro->>'idcentrorecurso' AS BIGINT));                 
                ELSE
                    RAISE EXCEPTION 'R-003, La persona ya se encuentra vinculada al recurso';
                END IF;
        WHEN 'eliminar' 
            THEN
                IF nullvalue(parametro->>'idrecurso') OR nullvalue(parametro->>'idcentrorecurso')  OR nullvalue(parametro->>'idpersona') THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE public.recursopersona
                SET rpfechafin = now()
                WHERE idrecurso = parametro->>'idrecurso' 
                AND idcentrorecurso = parametro->>'idcentrorecurso' 
                AND idpersona = parametro->>'idpersona'
                AND nullvalue(rpfechafin);

        WHEN 'obtenerRecurso' 
            THEN

               SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
                FROM (
                    SELECT *
                        FROM public.recurso p
                        NATURAL JOIN public.recursoestadotipo
                        NATURAL JOIN public.recursotipo
                    WHERE idestadotipo = 8 AND nullvalue(retfechafin) AND (idrecursotipo = parametro->>'idrecursotipo' 
                        AND (
                            parametro->>'rdescripcion' IS NULL
                            OR parametro->>'rdescripcion' = ''
                            OR rdescripcion ilike CONCAT('%', parametro->>'rdescripcion', '%')
                        ))
                LIMIT 50
                ) t;

                IF respuestajson_info IS NULL THEN
                    respuestajson_info = '[]';
                END IF;
        ELSE
	END CASE;

    --Parametros para la busqueda de la tabla asinconica
    buscar = parametro->>'search';
    pagesize = CAST(parametro->>'pageSize' AS INTEGER);
    numpage = CAST(parametro->>'page' AS INTEGER);

    IF respuestajson_info IS NULL THEN
        SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
        FROM (
           SELECT *, COUNT(*) OVER() AS totalCount
                FROM public.recursopersona
                NATURAL JOIN public.recurso
                NATURAL JOIN public.recursoestadotipo
                NATURAL JOIN public.recursotipo
                NATURAL JOIN public.ubicacion
                NATURAL JOIN ca.persona
                NATURAL JOIN ca.sector
            WHERE nullvalue(retfechafin)
            AND idestadotipo = 8
            AND nullvalue(rpfechafin)
            AND  (nullvalue(buscar) OR buscar = '' 
            OR CONCAT(
                COALESCE(rdescripcion, ''), 
                COALESCE(rtdescripcion, ''), 
                COALESCE(udescripcion, ''),
                COALESCE(penombre, ''),
                COALESCE(peapellido, '')
            ) ILIKE CONCAT('%', buscar, '%'))
            ORDER BY retfechaini DESC 
            LIMIT pagesize OFFSET (numpage - 1) * pagesize
        ) as t;
    END IF;

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
