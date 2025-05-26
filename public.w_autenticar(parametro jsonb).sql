CREATE OR REPLACE FUNCTION public.w_autenticar(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ /*select from w_autenticar('{"accion":"obs_","entorno":"desa"}'::jsonb);*/
DECLARE 
	    wsrurl varchar ;
		wsmetodo varchar;		
		wsusuario varchar;
		wspass varchar;
		respuestajson jsonb;
BEGIN
		
	IF(parametro->>'op'='obs_')THEN
		IF(parametro->>'entorno'='PROD')THEN
			wsrurl = 'http://' ;
		else
			wsrurl='http://';
		END IF;
		
		wsmetodo ='GET';		
		wsusuario = '';
		wspass =  '';		
	END IF;
	respuestajson = concat('{ "metodo":"', wsmetodo, '", "url":"', wsrurl,'", "usuario":"', wsusuario,'", "pass":"', wspass, '"}');

	--RAISE EXCEPTION 'R-004 WS_Login, Los datos informados no existen en el sistema o el usuario no se encuentra activo. Ingrese con otro factor. %',parametro;
	RETURN respuestajson;
	
END;
$function$
