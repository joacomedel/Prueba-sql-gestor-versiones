CREATE OR REPLACE FUNCTION public.w_notificarlicenciaempleado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idlicencia": 123456, "nrodoc": 43947118, "accion": "w_app_licencia_accion_buscartodas"}
*/
DECLARE
    respuestajson jsonb;
    rows_affected integer;
begin
    IF nullvalue(parametro->>'idlicencia') THEN 
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;

    UPDATE ca.licencia 
        SET linotificado = now() 
    WHERE idlicencia = parametro->>'idlicencia';

    -- Verifico si se realizo el update
    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    IF rows_affected > 0 THEN
        SELECT INTO respuestajson w_rrhh_abmlicencias_buscar(parametro);
    ELSE 
        RAISE EXCEPTION 'R-001, No se pudo notificar la licencia.';
    END IF;

    return respuestajson;

end;
$function$
