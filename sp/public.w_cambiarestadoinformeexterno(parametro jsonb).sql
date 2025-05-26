CREATE OR REPLACE FUNCTION public.w_cambiarestadoinformeexterno(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
*{"idinforme": 3, "centro": 1, "nroestado": 10}
* SP que modifica el estado del informe por el enviado en parametro->>'nroestado'
*/
	idinform BIGINT;
	respuestajson jsonb;
begin

	--Modifico el ultimo estado como finalizada
	UPDATE w_informefacturacionexternoestado 
		SET ifeefechafin = now()
	WHERE idinformefacturacionexterno = CAST(parametro->>'idinforme' AS BIGINT)
	AND idcentroinformefacturacionexterno = CAST(parametro->>'centro' AS INTEGER)
	AND nullvalue(ifeefechafin);

	--Creo el nuevo estado
	INSERT INTO w_informefacturacionexternoestado (idinformefacturacionexterno, idcentroinformefacturacionexterno, idinformefacturacionestadotipo) VALUES (
		CAST(parametro->>'idinforme' AS BIGINT), 
		CAST(parametro->>'centro' AS INTEGER), 
		CAST(parametro->>'nroestado' AS INTEGER)) 
		RETURNING idinformefacturacionexternoestado INTO idinform;

	respuestajson =	concat('{"idinformefacturacionexternoestado":"',idinform,'"}');
	
	return respuestajson;
end;
$function$
