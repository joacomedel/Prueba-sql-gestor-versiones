CREATE OR REPLACE FUNCTION public.w_app_abmactividadlaboral(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idusuarioweb": 5538, "accion": "obtener"}
*/
DECLARE
    respuestajson_info jsonb;
    respuestajson jsonb;
    vaccion character varying;
    rdatos RECORD;
begin
    IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'accion') THEN
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    vaccion = parametro->>'accion';
    CASE vaccion
        WHEN 'nuevo'
            THEN
                IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'aldescripcion') OR nullvalue(parametro->>'aldependencia') 
                OR nullvalue(parametro->>'idpersona') OR nullvalue(parametro->>'alfechafin') OR nullvalue(parametro->>'alfechainicio') THEN
                    RAISE EXCEPTION 'R-002, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                INSERT INTO ca.actividadlaboral (idusuarioweb, aldescripcion, aldependencia, idpersona, alfechafin, alfechainicio)
                VALUES (CAST(parametro->>'idusuarioweb' AS BIGINT), parametro->>'aldescripcion', parametro->>'aldependencia', CAST(parametro->>'idpersona' AS BIGINT), CAST(parametro->>'alfechafin' AS DATE), CAST(parametro->>'alfechainicio' AS DATE));

        WHEN 'modificar'
            THEN
                IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'aldescripcion') OR nullvalue(parametro->>'aldependencia') OR nullvalue(parametro->>'idactividadlaboral') 
                OR nullvalue(parametro->>'idpersona') OR nullvalue(parametro->>'alfechafin') OR nullvalue(parametro->>'alfechainicio')  THEN
                    RAISE EXCEPTION 'R-003, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE ca.actividadlaboral
                SET idusuarioweb = CAST(parametro->>'idusuarioweb' AS BIGINT),
                    aldescripcion = parametro->>'aldescripcion',
                    aldependencia = parametro->>'aldependencia',
                    idpersona = CAST(parametro->>'idpersona' AS BIGINT),
                    alfechafin = CAST(parametro->>'alfechafin' AS DATE),
                    alfechainicio = CAST(parametro->>'alfechainicio' AS DATE)
                WHERE idactividadlaboral = parametro->>'idactividadlaboral';
        WHEN 'eliminar'
            THEN
                IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'idactividadlaboral') THEN
                    RAISE EXCEPTION 'R-004, Todos los parametros deben estar completos.  %',parametro;
                END IF;

                UPDATE ca.actividadlaboral
                SET albaja = now(),
                    idusuarioweb = CAST(parametro->>'idusuarioweb' AS BIGINT)
                WHERE idactividadlaboral = parametro->>'idactividadlaboral';
                
        ELSE
	END CASE;

    SELECT INTO respuestajson_info w_app_obteneractividadlaboral(parametro);

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
