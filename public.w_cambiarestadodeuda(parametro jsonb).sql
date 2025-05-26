CREATE OR REPLACE FUNCTION public.w_cambiarestadodeuda(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"iddeuda":4546, "idcentrodedua": 1, "idctactedeudaclienteestadotipo": 3, "idusuarioweb": 5053, "deudatabla": "ctactedeudacliente"}
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
	IF nullvalue(parametro->>'iddeuda') OR nullvalue(parametro->>'idcentrodeuda') OR nullvalue(parametro->>'deudatabla') OR nullvalue(parametro->>'idctactedeudaclienteestadotipo') OR nullvalue(parametro->>'idusuarioweb') THEN 
		RAISE EXCEPTION 'R-001, Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;

	--Verifico que la tabla se encuentre en ctactedeudacliente
	IF parametro->>'deudatabla' = 'ctactedeudacliente' THEN
		--Borro estado anterior
		UPDATE ctactedeudaclienteestado
		SET ctctdefechafin = now()
		WHERE iddeuda = parametro->>'iddeuda' AND idcentrodeuda = parametro->>'idcentrodeuda' AND nullvalue(ctctdefechafin);

		--Cambio el estado
		INSERT INTO ctactedeudaclienteestado (iddeuda, idcentrodeuda, idctactedeudaclienteestadotipo, idusuarioweb) VALUES 
		(CAST(parametro->>'iddeuda' AS BIGINT), CAST(parametro->>'idcentrodeuda' AS BIGINT), CAST(parametro->>'idctactedeudaclienteestadotipo' AS BIGINT),  CAST(parametro->>'idusuarioweb' AS BIGINT));
	END IF;

	--Verifico que la deuda se enceuntre en cuentacorrientedeuda
	IF parametro->>'deudatabla' = 'cuentacorrientedeuda' THEN
		--Borro estado anterior
		UPDATE cuentacorrientedeudaestado
		SET ccdefechafin = now()
		WHERE iddeuda = parametro->>'iddeuda' AND idcentrodeuda = parametro->>'idcentrodeuda' AND nullvalue(ccdefechafin);

		--Cambio el estado
		INSERT INTO cuentacorrientedeudaestado (iddeuda, idcentrodeuda, idctactedeudaclienteestadotipo, idusuarioweb) VALUES 
		(CAST(parametro->>'iddeuda' AS BIGINT), CAST(parametro->>'idcentrodeuda' AS BIGINT), CAST(parametro->>'idctactedeudaclienteestadotipo' AS BIGINT),  CAST(parametro->>'idusuarioweb' AS BIGINT));
	END IF;

	return respuestajson;

	end;
	
$function$
