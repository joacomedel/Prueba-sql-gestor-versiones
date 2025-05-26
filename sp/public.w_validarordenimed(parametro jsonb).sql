CREATE OR REPLACE FUNCTION public.w_validarordenimed(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
       respuestajson jsonb;
       respuestajson_info jsonb;

	
BEGIN
    
	respuestajson =parametro;


	return respuestajson;

END;
$function$
