CREATE OR REPLACE FUNCTION public.w_buscaremisionauditada(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$

	-- SELECT w_buscaremisionauditada('{"nrodoc": "46990159", "tipodoc": "1"}')

DECLARE 
	rdatos RECORD;
	respuestajson jsonb;
BEGIN

	--Verifico que lleguen los datos necesarios para operar
	IF (parametro->>'nrodoc' IS NULL OR parametro->>'tipodoc' IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	PERFORM buscarrdatosfichamedicapendiente(CAST(parametro->>'nrodoc' AS VARCHAR),CAST(parametro->>'tipodoc' AS INTEGER));
	SELECT INTO rdatos array_to_json(array_agg(row_to_json(t))) AS practicas
            FROM (	
				SELECT *,concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) as codigopractica FROM ttfichamedicaemisionpendiente
			) as t;
	respuestajson = rdatos.practicas;

	RETURN respuestajson;
END;
$function$
