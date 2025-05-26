CREATE OR REPLACE FUNCTION public.w_abmrecurso(parametro jsonb)
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
                IF nullvalue(parametro->>'rdescripcion') OR nullvalue(parametro->>'idrecursotipo') OR nullvalue(parametro->>'idubicacion') THEN
                    RAISE EXCEPTION 'R-002 Todos los parametros deben estar completos.  %',parametro;
                END IF;

                SELECT INTO rdatos * 
                    FROM public.recurso 
                WHERE rdescripcion = parametro->>'rdescripcion' 
                    AND rdescripcionlarga = parametro->>'rdescripcionlarga'
                    AND idubicacion = parametro->>'idubicacion';

                IF NOT FOUND THEN
                    INSERT INTO public.recurso (rdescripcion, rdescripcionlarga, idrecursotipo, idubicacion, idcentroubicacion, codigobarra)
                    VALUES (parametro->>'rdescripcion', parametro->>'rdescripcionlarga', CAST(parametro->>'idrecursotipo' AS BIGINT), 
                    CAST(parametro->>'idubicacion' AS BIGINT),centro(), parametro->>'codigobarra')
                    RETURNING idrecurso, idcentrorecurso INTO vidrecurso, vidcentrorecurso;

                    INSERT INTO public.recursoestadotipo (retfechaini, idestadotipo, idrecurso, idcentrorecurso)
                    VAlUES (now(), 8, vidrecurso, vidcentrorecurso);
                ELSE
                    RAISE EXCEPTION 'R-003, El recurso ya se encuentra registrado.  %',parametro;
                END IF;
        WHEN 'modificar' 
            THEN
                IF nullvalue(parametro->>'idrecurso') OR nullvalue(parametro->>'rdescripcion') 
                OR nullvalue(parametro->>'idrecursotipo') OR nullvalue(parametro->>'idubicacion') OR nullvalue(parametro->>'idcentrorecurso') THEN
                    RAISE EXCEPTION 'R-005, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE public.recurso
                SET rdescripcion = parametro->>'rdescripcion', 
                    rdescripcionlarga = parametro->>'rdescripcionlarga', 
                    idrecursotipo = CAST(parametro->>'idrecursotipo' AS BIGINT), 
                    idubicacion = CAST(parametro->>'idubicacion' AS BIGINT),
                    codigobarra = parametro->>'codigobarra'
                WHERE idrecurso = parametro->>'idrecurso' 
                AND idcentrorecurso = parametro->>'idcentrorecurso';

        WHEN 'eliminar' 
            THEN
                IF nullvalue(parametro->>'idrecurso') OR nullvalue(parametro->>'idcentrorecurso') THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE public.recursoestadotipo
                SET retfechafin = now()
                WHERE idrecurso = parametro->>'idrecurso' 
                AND idcentrorecurso = parametro->>'idcentrorecurso'
                AND idestadotipo = 8;

                INSERT INTO public.recursoestadotipo (retfechaini, idestadotipo, idrecurso, idcentrorecurso)
                VAlUES (now(), 9, CAST(parametro->>'idrecurso' AS BIGINT), CAST(parametro->>'idcentrorecurso' AS BIGINT));

        WHEN 'obtenerDatosCarga' 
            THEN
                SELECT INTO respuestajson_info jsonb_build_object(
                    'ubicaciones', (
                        SELECT array_to_json(array_agg(row_to_json(t)))
                        FROM (
                            SELECT *
                            FROM public.ubicacion
                            WHERE nullvalue(fechabaja)
                        ) as t
                    ),
                    'recursotipo', (
                        SELECT array_to_json(array_agg(row_to_json(rt)))
                        FROM (
                            SELECT *
                            FROM public.recursotipo
                        ) as rt
                    )
                );
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
                    FROM public.recurso
                    NATURAL JOIN public.recursoestadotipo
                    NATURAL JOIN public.recursotipo
                    NATURAL JOIN public.ubicacion
                    NATURAL JOIN ca.sector
                    WHERE nullvalue(retfechafin)
                    AND idestadotipo = 8
                    AND  (nullvalue(buscar) OR buscar = '' 
                        OR CONCAT(
                            COALESCE(rdescripcion, ''), 
                            COALESCE(codigobarra, ''), 
                            COALESCE(rdescripcionlarga, ''), 
                            COALESCE(rtdescripcion, ''), 
                            COALESCE(udescripcion, '')
                        ) ILIKE CONCAT('%', buscar, '%'))
                    ORDER BY retfechaini DESC 
                    LIMIT pagesize OFFSET (numpage - 1) * pagesize
        ) as t;
    END IF;

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
