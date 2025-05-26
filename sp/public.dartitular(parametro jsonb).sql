CREATE OR REPLACE FUNCTION public.dartitular(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
* SELECT * FROM dartitular('{"nrodoc": "43947118"}')
*/
	rdatos RECORD;
	rdatostitu RECORD;
    respuestajson jsonb;
begin

	-- Verifico parametros
	IF(parametro->>'nrodoc' IS NULL) THEN
		RAISE EXCEPTION 'R-001 (EE), Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;

    --SL 12/04/24 - Busco datos del titular con el nrodoc del beneficiario
    SELECT INTO rdatos
            CASE WHEN not nullvalue(b.nrodoctitu)   THEN  b.nrodoctitu  
                WHEN not nullvalue(br.nrodoctitu)   THEN  br.nrodoctitu  
                WHEN (nullvalue(b.nrodoctitu) AND nullvalue(br.nrodoctitu)) THEN  p.nrodoc END as nrodoctitu,
            CASE WHEN not nullvalue(b.tipodoctitu)   THEN  b.tipodoctitu  
                WHEN not nullvalue(br.tipodoctitu)   THEN  br.tipodoctitu  
                WHEN (nullvalue(b.tipodoctitu) AND nullvalue(br.tipodoctitu)) THEN  p.tipodoc END as tipodoctitu
    FROM persona p 
    LEFT JOIN benefsosunc b USING (nrodoc,tipodoc)
    LEFT JOIN benefreci br USING (nrodoc,tipodoc)
    WHERE nrodoc = parametro->>'nrodoc';

    --SL 28/04/25 - Busco todos los datos datos del titular
    SELECT INTO rdatostitu * 
    FROM persona 
    WHERE nrodoc = rdatos.nrodoctitu AND tipodoc = rdatos.tipodoctitu;

	IF FOUND THEN 
        respuestajson = row_to_json(rdatostitu);
	ELSE
		-- Aviso que el informe no tiene ordenes
		RAISE EXCEPTION 'R-002, Error al buscar el titular %',parametro;
	END IF;

	return respuestajson;
end;
$function$
