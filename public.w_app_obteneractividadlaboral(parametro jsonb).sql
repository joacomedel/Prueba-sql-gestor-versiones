CREATE OR REPLACE FUNCTION public.w_app_obteneractividadlaboral(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idusuarioweb": 5538}
*/
DECLARE
    respuestajson jsonb;
begin
    IF nullvalue(parametro->>'idusuarioweb') THEN
        RAISE EXCEPTION 'R-005, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    SELECT INTO respuestajson array_to_json(array_agg(row_to_json(t)))
    FROM (
        SELECT *
        FROM ca.actividadlaboral
        LEFT JOIN ca.persona USING (idpersona)
        where nullvalue(albaja)
        order by idactividadlaboral DESC
    ) as t;
    return respuestajson;
end;
$function$
