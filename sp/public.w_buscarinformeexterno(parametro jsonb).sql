CREATE OR REPLACE FUNCTION public.w_buscarinformeexterno(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
* SP llamado desde "w_gestionarinformeexterno" para buscar datos de un informe
*/
	respuestajson jsonb;
	rdatosinf RECORD;
	rdatosord RECORD;
	rdatosarch RECORD;
begin
	-- Verifico parametros
	IF(parametro->>'idinforme' IS NULL OR parametro->>'centro' IS NULL) THEN
		RAISE EXCEPTION 'R-001 (BE), Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;

	-- Busco datos del informe
	SELECT INTO rdatosinf row_to_json(t) AS datainforme
	FROM (
        SELECT 
                idinformefacturacionexterno,
                idcentroinformefacturacionexterno,
                idinformefacturacionestadotipo,
	            ifetdescripcion,
                to_char(ifecreacion, 'DD/MM/YYYY HH:mm') AS ifecreacion,
                to_char(ifefechaini, 'DD/MM/YYYY') AS ifefechaini,
                to_char(ifefechafin, 'DD/MM/YYYY') AS ifefechafin
        FROM w_informefacturacionexterno
            NATURAL JOIN w_informefacturacionexternoestado
            NATURAL JOIN informefacturacionestadotipo
        WHERE idinformefacturacionexterno = parametro->> 'idinforme'
            AND idcentroinformefacturacionexterno = parametro->> 'centro'
            AND ifeefechafin IS NULL
	) as t;

	-- Busco las ordenes del informe
    SELECT INTO rdatosord array_to_json(array_agg(row_to_json(t))) as datainformeord
	FROM (  
        SELECT 
            o.nroorden,
            o.centro,
            concat(case when (o.centro < 10) then concat('0',o.centro) else o.centro::VARCHAR end, '-',concat('0',o.nroorden)) AS nroordencentro,
            nrodoc AS nrodocafil,
            barra,
            concat(apellido,', ',nombres) AS afiliado,
            date(ptutilizado) AS fechaconsumo,
            p.pnombrefantasia AS nombreprestador,
            p.pcuit AS cuitprestador,
            case when (pra.pdescripcion IS NULL) THEN ct.ctdescripcion ELSE pra.pdescripcion END AS pdescripcion,
            orc.idrecibo AS idrecibo,
            SUM(case when (it.cantidad IS NULL) THEN 1 ELSE it.cantidad END)  AS cantidad
        FROM w_informefacturacionexterno
            NATURAL JOIN w_informefacturacionexternoestado
            NATURAL JOIN w_informefacturacionexternoordenestado
            NATURAL JOIN w_informefacturacionexternoorden AS ifeo
            JOIN ordenrecibo orc ON (orc.nroorden = ifeo.nroorden AND orc.centro = ifeo.centroorden)
            JOIN recibo_token rt USING (idrecibo)
            JOIN orden as o ON (o.nroorden = ifeo.nroorden AND o.centro = ifeo.centroorden)
            JOIN persona_token as pk on(pk.pttoken = rt.pttoken)
            JOIN w_persona_token_info AS pti USING (idpersonatoken)
            JOIN persona USING (nrodoc)
            JOIN prestador AS p USING (idprestador)
            JOIN comprobantestipos AS ct ON(o.tipo=ct.idcomprobantetipos)
            JOIN itemvalorizada AS itv ON (itv.nroorden = orc.nroorden AND itv.centro = orc.centro)
            JOIN item it ON (it.iditem = itv.iditem AND it.centro = itv.centro)
            JOIN practica as pra ON (pra.idnomenclador = it.idnomenclador AND pra.idcapitulo = it.idcapitulo AND pra.idsubcapitulo = it.idsubcapitulo AND pra.idpractica = it.idpractica)
        WHERE idinformefacturacionexterno = parametro->> 'idinforme'
            AND idcentroinformefacturacionexterno = parametro->> 'centro'
            AND ifeefechafin IS NULL
            AND ifeoeliminado IS NULL
            AND ieoefechafin IS NULL
            AND idordenestadotipos = 4
        GROUP BY o.nroorden, o.centro, nrodoc, barra, apellido, nombres, ptutilizado, p.pnombrefantasia, p.pcuit, ct.ctdescripcion, pra.pdescripcion, orc.idrecibo
        ORDER BY ptutilizado DESC
	) as t;

	-- Busco los archivos del informe
    SELECT INTO rdatosarch array_to_json(array_agg(t.archivos)) as datainformearch
    FROM ( 
        SELECT w_obtener_archivo(jsonb_build_object('idarchivo', idarchivo, 'idcentroarchivo', idcentroarchivo)) AS archivos
        FROM w_informefacturacionexterno
            NATURAL JOIN w_informefacturacionexternoestado
            NATURAL JOIN w_informefacturacionexternoarchivo 
        WHERE idinformefacturacionexterno = parametro->> 'idinforme'
            AND idcentroinformefacturacionexterno = parametro->> 'centro'
            AND ifeefechafin IS NULL
    ) as t;

    --Unifico datos en un solo arrelgo
	respuestajson =  jsonb_build_object(
        'datainforme', rdatosinf.datainforme,
        'datainformeord', rdatosord.datainformeord,
        'datainformearch', rdatosarch.datainformearch
    );
	return respuestajson;
end;
$function$
