CREATE OR REPLACE FUNCTION public.w_obtenerdatosinformeexterno(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
/*
* SP llamado desde "w_gestionarinformeexterno" para buscar todos los datos de un informe y ordenes disponibles para consumir 
*/
	-- RECORD
	rdatos RECORD;
	datosord jsonb;
	-- VARIABLES
	respuestajson jsonb;
begin
	SELECT INTO rdatos COALESCE(array_to_json(array_agg(row_to_json(t))), '[]') AS dataord
	FROM (
        SELECT MIN(concat(apellido,', ',nombres)) as afiliado, 
            MIN(barra),
            MIN(nrodoc),
            MIN(concat(case when (o.centro < 10) then concat('0',o.centro) else o.centro::VARCHAR end, '-',concat('0',o.nroorden))) AS nroordencentro,
            o.nroorden AS nroorden,
            o.centro AS centro,
			MIN(date(ptutilizado)) AS fechaconsumo,
            MIN(ptidescripcion) AS descripcion,
            MIN(pnombrefantasia),
            MIN(pcuit),
        	MIN(case when (pra.pdescripcion IS NULL) THEN ct.ctdescripcion ELSE pra.pdescripcion END) AS pdescripcion
			FROM w_persona_token_info 
				NATURAL JOIN prestador 
				JOIN persona_token as pk USING (idpersonatoken) 
				JOIN recibo_token rt USING (pttoken)
				JOIN ordenrecibo orc ON (orc.idrecibo = rt.idrecibo AND orc.centro = rt.centro)
				JOIN orden as o ON (o.nroorden = orc.nroorden AND o.centro = orc.centro)
				JOIN comprobantestipos AS ct ON(o.tipo=ct.idcomprobantetipos)
				LEFT JOIN itemvalorizada AS itv ON (itv.nroorden = orc.nroorden AND itv.centro = orc.centro)
				LEFT JOIN item it ON (it.iditem = itv.iditem AND it.centro = itv.centro)
				LEFT JOIN practica as pra ON (pra.idnomenclador = it.idnomenclador AND pra.idcapitulo = it.idcapitulo AND pra.idsubcapitulo = it.idsubcapitulo AND pra.idpractica = it.idpractica)
				LEFT JOIN w_informefacturacionexternoordenestado AS ifeoe ON (ifeoe.nroorden = o.nroorden AND ifeoe.centroorden = o.centro)
				LEFT JOIN w_informefacturacionexternoorden AS ifeo ON (ifeo.nroorden = o.nroorden AND ifeo.centroorden = o.centro)
				JOIN persona USING (nrodoc) 
		WHERE (idusuariowebgestor = parametro->>'idusuariowebgestor' OR idprestador = CAST(parametro->>'idprestador' AS BIGINT))
			AND ((nullvalue(idinformefacturacionexterno) AND nullvalue(idcentroinformefacturacionexterno)) OR (nullvalue(ieoefechafin) AND idordenestadotipos = 3))			AND date(ptutilizado) BETWEEN parametro->> 'fechaini' AND parametro->> 'fechafin' 
			AND (
				CASE
					WHEN parametro->> 'prestadorSelect' IS NOT NULL THEN 
						idprestador = parametro->> 'prestadorSelect'
					ELSE true
				END
			)			
		GROUP BY o.nroorden, o.centro 
        ORDER BY MIN(ptutilizado) DESC
	) as t;
	-- Busco las ordenes del informe
	SELECT INTO datosord w_buscarinformeexterno(parametro);
	respuestajson = json_build_object('ordenes', rdatos.dataord)::text;			
	respuestajson =	respuestajson || datosord;		

	return respuestajson;
end;

$function$
