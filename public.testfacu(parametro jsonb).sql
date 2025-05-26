CREATE OR REPLACE FUNCTION public.testfacu(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE

    respuestajson jsonb;

BEGIN

    respuestajson = parametro;

    return respuestajson;

END;$function$
