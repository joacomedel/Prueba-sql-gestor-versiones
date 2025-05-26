CREATE OR REPLACE FUNCTION public.w_agregarinformeexterno(parametro jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/*
* SP llamado desde "w_gestionarinformeexterno" para agregar o eliminar ordenes de un informe 
*/
	paramOrd jsonb;
	arrayOrd jsonb[];
	rcant INTEGER;
	rdatos RECORD;
begin
	-- Verifico parametros
	IF(parametro->>'idinforme' IS NULL AND parametro->'arrayOrd' IS NULL) THEN
		RAISE EXCEPTION 'R-001 (AE), Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;


	-- Elimino todas las ordenes del informe
	FOR rdatos IN
		SELECT *
		FROM w_informefacturacionexternoorden
		LEFT JOIN w_informefacturacionexternoordenestado AS ifeoe USING (nroorden, centroorden)
		WHERE idinformefacturacionexterno = CAST(parametro->>'idinforme' AS INTEGER)
			AND idcentroinformefacturacionexterno = CAST(parametro->>'centro' AS INTEGER)
			AND (nullvalue(ieoefechafin) AND idordenestadotipos	 = 4)
			AND nullvalue(ifeoeliminado)
	LOOP
		-- Verifico que las ordenes no se encuentren asociadas a otro informe
		-- SELECT INTO rcant count(*) FROM w_informefacturacionexternoordenestado 
		-- 	WHERE nroorden = rdatos.nroorden AND idordenestadotipos = 4;
			
		-- IF FOUND THEN
		-- 	RAISE EXCEPTION 'R-002, La orden %-% ya se encuentra asociada a otro informe', rdatos.nroorden, rdatos.centroorden;
		-- END IF;

		RAISE NOTICE 'NroOrden: %, Centro: %', rdatos.nroorden, rdatos.centroorden;
		--Cambio el estado de la orden a "des-vinculada"
		PERFORM w_cambiarestadoinformeexternoorden(jsonb_build_object('nroorden', rdatos.nroorden, 'centro', rdatos.centroorden, 'nroestado', 3));

		--Elimino la relacion
		UPDATE w_informefacturacionexternoorden
			SET ifeoeliminado = now()
		WHERE nroorden = CAST(rdatos.nroorden AS INTEGER)
		AND centroorden = CAST(rdatos.centroorden AS INTEGER);

	END LOOP;

	--Transformo el JSON en array para poder recorrerlo en un FOREACH
	arrayOrd := ARRAY(SELECT jsonb_array_elements_text(parametro->'arrayOrd'));
	RAISE NOTICE 'arrayOrd: %', arrayOrd;
	
	--Recorro array de ordenes
	FOREACH paramOrd IN ARRAY arrayOrd
	LOOP
		RAISE NOTICE 'paramOrd: %', paramOrd;
		RAISE NOTICE 'parametro: %', parametro;

		--Verifico si la orden ya esta asociada al informe
		SELECT INTO rcant count(*) FROM w_informefacturacionexternoorden 
			WHERE idinformefacturacionexterno = CAST(parametro->>'idinforme' AS INTEGER)
			AND idcentroinformefacturacionexterno = CAST(parametro->>'centro' AS INTEGER)
			AND nroorden = CAST(paramOrd->>'nroorden' AS INTEGER)
			AND centroorden = CAST(paramOrd->>'centro' AS INTEGER);

		RAISE NOTICE 'cantidad ordenes: %', rcant;

		IF (rcant = 0) THEN
			--Creo la relacion entre las ordenes y el informe
			INSERT INTO w_informefacturacionexternoorden (idinformefacturacionexterno, idcentroinformefacturacionexterno, nroorden, centroorden) 
			VALUES (CAST(parametro->>'idinforme' AS INTEGER), CAST(parametro->>'centro' AS INTEGER), CAST(paramOrd->>'nroorden' AS INTEGER), CAST(paramOrd->>'centro' AS INTEGER));
		END IF;
		--Cambio el estado de la orden a "vinculada"
		PERFORM w_cambiarestadoinformeexternoorden(jsonb_build_object('nroorden', paramOrd->>'nroorden', 'centro', paramOrd->>'centro', 'nroestado', 4));
		
		--Reutilizo la relacion eliminada
		UPDATE w_informefacturacionexternoorden
			SET ifeoeliminado = NULL
		WHERE idinformefacturacionexterno = CAST(parametro->>'idinforme' AS INTEGER)
		AND idcentroinformefacturacionexterno = CAST(parametro->>'centro' AS INTEGER)
		AND nroorden = CAST(paramOrd->>'nroorden' AS INTEGER)
		AND centroorden = CAST(paramOrd->>'centro' AS INTEGER);

	END LOOP;		
	return true;
end;$function$
