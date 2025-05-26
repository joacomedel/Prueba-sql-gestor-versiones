CREATE OR REPLACE FUNCTION public.w_crearinformeexterno(parametro jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
* SP llamado desde "w_gestionarinformeexterno" para crear el informe al prestador
*/
	idinform BIGINT;
	idcentro INTEGER;
	rcant INTEGER;
begin
	-- Verifico parametros
	IF(parametro->>'ifefechaini' IS NULL AND parametro->>'ifefechafin' IS NULL) THEN
		RAISE EXCEPTION 'R-001 (CE), Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;

	--Busco los informes pendientes que tiene el prestador
	SELECT INTO rcant count(*) FROM w_informefacturacionexterno 
		NATURAL JOIN w_informefacturacionexternoestado
	WHERE idusuariowebgestor = CAST(parametro->>'idusuariowebgestor' AS BIGINT)
		AND nullvalue(ifeefechafin)
		AND idinformefacturacionestadotipo = 1;

	-- Verifico que no exceda los 15 informes pendientes
	IF(rcant > 15) THEN
		RAISE EXCEPTION 'R-002, Cuenta con % informes pendientes. Si necesita crear envie o cancele los pendientes',rcant;
	END IF;

	--Creo el informe
	INSERT INTO w_informefacturacionexterno (idusuariowebgestor	, idcentroinformefacturacionexterno, ifefechaini, ifefechafin)
		VALUES (
			CAST(parametro->>'idusuariowebgestor' AS BIGINT), 
			centro(),
			(parametro->>'ifefechaini')::timestamp,
			(parametro->>'ifefechafin')::timestamp
			) 
		RETURNING idinformefacturacionexterno, idcentroinformefacturacionexterno INTO idinform, idcentro;

	IF (idinform IS NULL OR idcentro IS NULL) THEN
		RAISE EXCEPTION 'R-003, No se pudo crear el informe.  %',parametro;
	END IF;

	--Inicio el estado en des-vinculada
	PERFORM w_cambiarestadoinformeexterno(jsonb_build_object('idinforme', idinform, 'centro', idcentro, 'nroestado', 1));
	return true;
end;
$function$
