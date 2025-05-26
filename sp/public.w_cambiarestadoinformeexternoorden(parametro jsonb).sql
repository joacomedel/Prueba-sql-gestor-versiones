CREATE OR REPLACE FUNCTION public.w_cambiarestadoinformeexternoorden(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
*{"nroorden": 144414, "centro": 1, "nroestado": 2}
* SP que modifica el estado del informe por el enviado en parametro->>'nroestado'
*/
	idinform BIGINT;
	respuestajson jsonb;
begin

	--Modifico el ultimo estado como finalizada
	UPDATE w_informefacturacionexternoordenestado 
		SET ieoefechafin = now()
	WHERE nroorden = CAST(parametro->>'nroorden' AS INTEGER) 
	AND centroorden = CAST(parametro->>'centro' AS INTEGER) 
	AND nullvalue(ieoefechafin);

	--Creo el nuevo estado
	INSERT INTO w_informefacturacionexternoordenestado (nroorden, centroorden, idordenestadotipos	) VALUES (
	CAST(parametro->>'nroorden' AS INTEGER), 
	CAST(parametro->>'centro' AS INTEGER), 
	CAST(parametro->>'nroestado' AS INTEGER)) 
	RETURNING idinformefacturacionexternoordenestado INTO idinform;

	respuestajson =	concat('{"idinformefacturacionexternoordenestado":"',idinform,'"}');
	
	return respuestajson;
end;
$function$
