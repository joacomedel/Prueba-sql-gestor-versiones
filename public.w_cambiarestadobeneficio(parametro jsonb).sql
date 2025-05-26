CREATE OR REPLACE FUNCTION public.w_cambiarestadobeneficio(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idbeneficio":4546, "idusuarioweb": 5053, "idbeneficioestadotipo": 1}
*/
DECLARE
--VARIABLES 
	paramdatosafil jsonb;
	respuestajson jsonb;
	jdeuda jsonb;
	arraydeuda jsonb[];
--RECORD
      rdeuda RECORD;
      rmpoperacion RECORD;
begin
	IF nullvalue(parametro->>'idbeneficio') OR nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'idbeneficioestadotipo') THEN 
		RAISE EXCEPTION 'R-001, Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;

	--Borro estado anterior
	UPDATE w_beneficioestado
	SET befechafin = now()
	WHERE idbeneficio = parametro->>'idbeneficio' AND nullvalue(befechafin);

	--Cambio el estado
	INSERT INTO w_beneficioestado (idbeneficio, idbeneficioestadotipo, idusuarioweb) VALUES 
	(CAST(parametro->>'idbeneficio' AS BIGINT),
	CAST(parametro->>'idbeneficioestadotipo' AS BIGINT),  
	CAST(parametro->>'idusuarioweb' AS BIGINT));

	return respuestajson;

	end;
	
$function$
