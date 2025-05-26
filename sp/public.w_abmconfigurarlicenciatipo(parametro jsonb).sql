CREATE OR REPLACE FUNCTION public.w_abmconfigurarlicenciatipo(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"nrodoc":"43947118","accion":"obtener"}
*/
DECLARE
    respuestajson_info jsonb;
    respuestajson jsonb;
    usuariojson jsonb;
    vaccion character varying;
    rdatos RECORD;
begin
    IF nullvalue(parametro->>'nrodoc') OR nullvalue(parametro->>'accion') THEN
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    SELECT INTO usuariojson * FROM sys_dar_usuario_web(parametro);
    vaccion = parametro->>'accion';
    CASE vaccion
        WHEN 'nuevo'
            THEN
                IF usuariojson IS NULL OR nullvalue(parametro->>'ltccontidaddias') THEN
                    RAISE EXCEPTION 'R-003, Todos los parametros deben estar completos.  %',parametro;
                END IF; 

                UPDATE ca.licenciatipoconfiguracion
                SET ltccontidaddias = CAST(parametro->>'ltccontidaddias' AS BIGINT),
                    ltcusuariocarga = CAST(usuariojson->>'idusuario' AS INTEGER),
                    ltcfechavigencia = CAST(parametro->>'ltcfechavigencia' AS TIMESTAMP)
                WHERE idlicenciatipoconfiguracion = parametro->>'idlicenciatipoconfiguracion';
        WHEN 'modificar'
            THEN
                IF usuariojson IS NULL OR nullvalue(parametro->>'idlicenciatipoconfiguracion') OR nullvalue(parametro->>'ltccontidaddias') THEN
                    RAISE EXCEPTION 'R-003, Todos los parametros deben estar completos.  %',parametro;
                END IF; 

                UPDATE ca.licenciatipoconfiguracion
                SET ltccontidaddias = CAST(parametro->>'ltccontidaddias' AS BIGINT),
                    ltcusuariocarga = CAST(usuariojson->>'idusuario' AS INTEGER),
                    ltcfechavigencia = CAST(parametro->>'ltcfechavigencia' AS TIMESTAMP)
                WHERE idlicenciatipoconfiguracion = parametro->>'idlicenciatipoconfiguracion';
        ELSE
	END CASE;

    SELECT INTO respuestajson_info w_obtenerlicenciatipoconfiguracion(parametro);

    respuestajson = respuestajson_info;
    return respuestajson;
end;
$function$
