CREATE OR REPLACE FUNCTION public.w_obtenerlicenciatipoconfiguracion(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idusuarioweb": 5538}
*/
DECLARE
    respuestajson jsonb;
begin
    IF nullvalue(parametro->>'nrodoc') THEN
        RAISE EXCEPTION 'R-005, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    SELECT INTO respuestajson array_to_json(array_agg(row_to_json(t)))
    FROM (
        SELECT *
        FROM ca.licenciatipoconfiguracion
        LEFT JOIN ca.persona USING (idpersona)
        NATURAL JOIN ca.licenciatipo
        where nullvalue(ltcfechavigencia)
        order by idpersona DESC
    ) as t;
    return respuestajson;
end;
$function$
