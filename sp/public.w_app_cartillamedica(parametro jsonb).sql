CREATE OR REPLACE FUNCTION public.w_app_cartillamedica(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$

DECLARE
    --RECORD
	rdatos RECORD;
	--VARIABLES
	respuestajson_info jsonb; 
	respuestajson jsonb;

BEGIN

	-- Traigo todos los datos de los medicos
	SELECT INTO rdatos  array_to_json(array_agg(row_to_json(t))) AS cartilla
		FROM (		
			SELECT  ipnombrefantasia, ipespecialidad, ipcontacto, ipdireccion, iplocalidad FROM importarprestador WHERE nullvalue(ipfechaultimaactualizacion)
		) as t;
	IF FOUND THEN
		respuestajson_info = rdatos.cartilla;
		respuestajson = respuestajson_info;
	ELSE
		respuestajson_info = '{"datos":[]}';
		respuestajson = respuestajson_info;
	END IF;
	RETURN respuestajson;
END

$function$
