CREATE OR REPLACE FUNCTION public.w_generarcredencialesvalidaciononline(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"cuit": "20-23507924-1", "usuarioweb": "usuprueba", "contrasenia": "usuprueba"}
*/
DECLARE
    respuestajson jsonb;
    rprestador RECORD;
begin
    IF nullvalue(parametro->>'cuit') OR nullvalue(parametro->>'usuarioweb') OR nullvalue(parametro->>'contrasenia') THEN
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;

    -- Verifico si existe el prestador para crear el usuario
    SELECT INTO rprestador * FROM prestador WHERE pcuit = parametro->>'cuit';
    IF FOUND THEN
        INSERT INTO public.w_usuarioweb (uwnombre,uwcontrasenia,uwmail,uwsuscripcionnl,uwverificador,uwactivo,uwlimpiar,uwtipo,uwemailverificado,uwimagen)
        VALUES(parametro->>'usuarioweb',MD5(parametro->>'contrasenia'),rprestador.pmail,TRUE,NULL,TRUE,FALSE,2,FALSE,NULL);
    ELSE
        RAISE EXCEPTION 'R-002, No se encontro el prestador.  %',parametro;
    END IF;


    -- SELECT INTO respuestajson array_to_json(array_agg(row_to_json(t)))
    -- FROM (
    --     SELECT *
    --     FROM ca.licenciatipoconfiguracion
    --     LEFT JOIN ca.persona USING (idpersona)
    --     NATURAL JOIN ca.licenciatipo
    --     where nullvalue(ltcfechavigencia)
    --     order by idpersona DESC
    -- ) as t;
    return respuestajson;
end;
$function$
