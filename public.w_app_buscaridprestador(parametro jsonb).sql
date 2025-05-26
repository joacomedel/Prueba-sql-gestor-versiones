CREATE OR REPLACE FUNCTION public.w_app_buscaridprestador(parametro jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$

--SELECT w_app_buscaridprestador('{"pcuit": "20-23507924-1"}');
DECLARE
	--VARIABLES
	vidprestador BIGINT;
	respuestajson jsonb;
BEGIN
	IF ((parametro ->> 'pcuit') IS NULL) THEN
		RAISE EXCEPTION 'R-001 (BP), Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	SELECT INTO vidprestador idprestador FROM prestador WHERE pcuit = parametro ->> 'pcuit'
	ORDER BY prestadorcc DESC
	LIMIT 1;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'R-001 (BP), No se encontró el prestador con el cuit, %', parametro ->> 'pcuit';
	END IF;

	RETURN vidprestador;
END;

$function$
