CREATE OR REPLACE FUNCTION public.w_issn_isafiliadodni(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$

DECLARE
       respuestajson jsonb;
       respuestajson_info jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       carticulo refcursor;


       url varchar;
	
BEGIN
     --RAISE NOTICE 'parametros %',parametro;
     --respuestajson_info =concat(' { "url":"http://apps2.issn.gov.ar:8080/WS_SE_SIA_PROD/webservicesentidaddesa/servlet/com.webservicesentidaddesa.aisafiliadodni?wsdl","metodo":"Execute","param":[{"Userkey":"","Cuilkey":"HEnP5HGtU3eTTcd8V6dwTA==","Passkey":"zDEC01wQBhQ+RkqYsuJpEQ==","Codaplicacion":"134","Numafiliado":"21380587","Fecpresta":"2022-09-20"}]}');  
     
     --respuestajson_info = parametro;
     respuestajson =respuestajson_info;

    --respuestajson=respuestajson_info;





    return respuestajson;

END;
$function$
