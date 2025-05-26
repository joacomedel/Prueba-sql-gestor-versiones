CREATE OR REPLACE FUNCTION public.w_enviarinformeexterno(parametro jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
* SP llamado desde "w_gestionarinformeexterno" para enviar el informe al prestador
*/
	rdatos RECORD;
    arrayArch jsonb[];
    paramArch jsonb;
begin

	-- Verifico parametros
	IF(parametro->>'idinforme' IS NULL AND parametro->>'centro' IS NULL) THEN
		RAISE EXCEPTION 'R-001 (EE), Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;

    --Verifico si tiene archivos para subir
    IF parametro->>'archivos' IS NOT NULL THEN
        --Transformo el JSON en array para poder recorrerlo en un FOREACH
        arrayArch := ARRAY(SELECT jsonb_array_elements_text(parametro->'archivos'));
        RAISE NOTICE 'arrayOrd: %', arrayArch;

        FOREACH paramArch IN ARRAY arrayArch

        LOOP
            INSERT INTO w_informefacturacionexternoarchivo(idinformefacturacionexterno, idcentroinformefacturacionexterno, idarchivo, idcentroarchivo) VALUES 
                (CAST(parametro->>'idinforme' AS BIGINT), 
                CAST(parametro->>'centro' AS BIGINT), 
                CAST(paramArch->>'idarchivo' AS BIGINT), 
                CAST(paramArch->>'idcentroarchivo' AS BIGINT));
        END LOOP;
    END IF;

	-- Verifico que el informe tenga ordenes
	SELECT INTO rdatos * FROM w_informefacturacionexternoestado
		NATURAL JOIN w_informefacturacionexternoorden
	WHERE idinformefacturacionexterno = parametro->>'idinforme'
		AND idcentroinformefacturacionexterno = parametro->>'centro'
		AND nullvalue(ifeefechafin)
		AND nullvalue(ifeoeliminado)
		AND idinformefacturacionestadotipo <> 10;
	IF FOUND THEN 
		-- LLamo SP que cambia el estado del informe
		PERFORM w_cambiarestadoinformeexterno(jsonb_build_object('idinforme', parametro->>'idinforme', 'centro', parametro->>'centro', 'nroestado', 10));
	ELSE
		-- Aviso que el informe no tiene ordenes
		RAISE EXCEPTION 'R-002, El informe no tiene ordenes asociadas o ya fue enviada.  %',parametro;
	END IF;

	return true;
end;
$function$
