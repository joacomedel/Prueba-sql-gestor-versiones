CREATE OR REPLACE FUNCTION public.w_issn_isafiliadodni_respuesta(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$


DECLARE
       respuestajson jsonb;
       respuestajson_info jsonb;
       jsonafiliado jsonb;


	
BEGIN

    respuestajson=parametro;

    return respuestajson;

END;
$function$
