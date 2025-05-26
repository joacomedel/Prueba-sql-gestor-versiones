CREATE OR REPLACE FUNCTION public.w_puenteparametros(parametro jsonb)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    -- Facu 12-03-2025
    respuestajson jsonb;

BEGIN

    respuestajson = parametro;

    return respuestajson;

END;


$function$
