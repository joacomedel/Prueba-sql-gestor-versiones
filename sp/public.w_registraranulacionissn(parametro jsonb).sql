CREATE OR REPLACE FUNCTION public.w_registraranulacionissn(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$



DECLARE
       respuestajson jsonb;
       respuestajson_info jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;

       rafiliado RECORD;

       cafiliado refcursor;


       elem RECORD;




	
BEGIN

	
	--respuestajson_info = parametro->>'Resultado';

--[0] => {"Mutuales":[{"CodigoMutual":12,"Nombre":"MUPOL","Porcentaje":20,"Aplica":"C"}]}


	


	respuestajson=parametro;
	--RAISE NOTICE  'Calling cs_create_job(%)', respuestajson->>'Resultado';
	--RAISE NOTICE  'Calling cs_create_job(%)', respuestajson_info->>'NumeroAutorizacion';
	--RAISE NOTICE  'Calling cs_create_job(%)', respuestajson_info->>'Modalidad';

	--respuestajson = parametro;

	return respuestajson;

END;
$function$
