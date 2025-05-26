CREATE OR REPLACE FUNCTION public.w_app_getversion()
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
* SELECT  w_app_getversion()
*/
DECLARE
    respuestajson jsonb;
    versionactual character varying := '2.9.1';

BEGIN

    respuestajson := jsonb_build_object('version', versionactual);

    RETURN respuestajson;
END;
 
$function$
