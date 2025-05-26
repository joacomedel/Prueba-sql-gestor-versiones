CREATE OR REPLACE FUNCTION public.w_registrarvalidacionimed(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
       respuestajson jsonb;
       respuestajson_info jsonb;



	
BEGIN

	
	respuestajson_info = parametro->>'Resultado';

	INSERT INTO far_validacionimed( fvrespuesta,fvnumeroautorizacion,fvmodalidad)
	VALUES (
		parametro,
		(respuestajson_info->>'NumeroAutorizacion')::integer,
		(respuestajson_info->>'Modalidad')::integer


		);
	


	respuestajson=parametro;
	RAISE NOTICE  'Calling cs_create_job(%)', respuestajson->>'Resultado';
	RAISE NOTICE  'Calling cs_create_job(%)', respuestajson_info->>'NumeroAutorizacion';
	RAISE NOTICE  'Calling cs_create_job(%)', respuestajson_info->>'Modalidad';

	--respuestajson = parametro;

	return respuestajson;

END;
$function$
