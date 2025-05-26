CREATE OR REPLACE FUNCTION public.w_app_consumostoken(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
-- {"token": "token", "accion":'buscar'}
DECLARE
    --RECORD
	rdatos RECORD;
	rusuariovalidador RECORD;
	--VARIABLES
	respuestajson_info jsonb; 
	respuestajson jsonb;
	vidprestador BIGINT;
	respuestaconsumojson jsonb;

BEGIN
	IF ((parametro ->> 'accion') IS NULL OR (parametro ->> 'idusuariowebgestor') IS NULL) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	IF (parametro ->> 'pcuit') IS NOT NULL THEN
		SELECT INTO vidprestador w_app_buscaridprestador(parametro);
	END IF;

	-- Busco el token y devuelvo a que afiliado pertenece 
    IF (parametro ->> 'accion' = 'buscar') THEN
		SELECT INTO rdatos nrodoc , apellido, nombres, barra, 
		case when (pra.pdescripcion IS NULL) THEN 'Consulta' ELSE pra.pdescripcion END AS pdescripcion
		FROM persona_token pk
			NATURAL JOIN persona 
			JOIN recibo_token rt USING (pttoken)
			-- SL 04/04/24 - Agrego condicion para buscar la orden en caso de que haya un recibo > muchas ordenes
			JOIN ordenrecibo orc ON (orc.idrecibo = rt.idrecibo AND orc.centro = rt.centro AND (length(pk.pttoken) >= 6 AND pk.pttoken ilike concat(orc.nroorden, orc.centro, '%')))
			LEFT JOIN itemvalorizada AS itv ON (itv.nroorden = orc.nroorden AND itv.centro = orc.centro)
			LEFT JOIN item it ON (it.iditem = itv.iditem AND it.centro = itv.centro)
			LEFT JOIN practica as pra ON (pra.idnomenclador = it.idnomenclador AND pra.idcapitulo = it.idcapitulo AND pra.idsubcapitulo = it.idsubcapitulo AND pra.idpractica = it.idpractica)
		WHERE pttoken = parametro ->> 'token';
		IF FOUND THEN
			respuestajson_info = row_to_json(rdatos);
			respuestajson = respuestajson_info;
		END IF;
	END IF;
	-- Consumo el token
	IF (parametro ->> 'accion' = 'consumir') THEN
		IF ((parametro ->> 'info_consumio_token') IS NULL OR (parametro->> 'descripcion') IS NULL) THEN
			RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
		ELSE
		--SL 19/01/24 - Agrego condicion para que los token de firma no se puedan consumir como ordenes
			SELECT INTO rdatos * FROM persona_token 
				LEFT JOIN w_persona_token_info USING (idpersonatoken)
			WHERE pttoken = parametro->> 'token'
				AND (nullvalue(ptidescripcion) OR ptidescripcion <> 'Firma APP')
				AND ptfechavencimiento > now();
			IF FOUND THEN
				SELECT INTO respuestaconsumojson w_consumir_token_afiliado(parametro);
				IF FOUND THEN
                
                    --SL 17/07/24 - Agrego busqueda de usuario validador
                    SELECT INTO rusuariovalidador * FROM w_usuarioweb WHERE uwnombre = parametro->>'uwnombre';
                
					INSERT INTO w_persona_token_info (ptidescripcion, idpersonatoken, idprestador, idcentropersonatoken, idusuariowebgestor, idusuariowebvalidador) 
					VALUES (parametro->>'descripcion'::VARCHAR, (respuestaconsumojson->>'idpersonatoken')::BIGINT, vidprestador, 
                    (respuestaconsumojson->>'idcentropersonatoken')::INTEGER, (parametro->>'idusuariowebgestor')::BIGINT, rusuariovalidador.idusuarioweb);
					SELECT INTO rdatos * FROM w_persona_token_info 
						WHERE idpersonatoken = respuestaconsumojson->>'idpersonatoken' 
						AND idcentropersonatoken = respuestaconsumojson->>'idcentropersonatoken';
					IF FOUND THEN 
						respuestajson_info = row_to_json(rdatos);
						respuestajson = respuestajson_info;
					END IF;
				ELSE
					RAISE EXCEPTION 'R-003, Error al consumir token del afiliado';
				END IF;
			ELSE
				RAISE EXCEPTION 'R-004, El token está vencido o no corresponde como una orden';
			END IF;
		END IF;
	END IF;
	-- Devuelvo todas las ordenes dependiendo el prestador
    IF (parametro ->> 'accion' = 'obtener') THEN
			SELECT INTO rdatos  array_to_json(array_agg(row_to_json(t))) AS data
				FROM (
			SELECT MIN(concat(apellido,', ',nombres)) as afiliado, 
				MIN(concat(case when (o.centro < 10) then concat('0',o.centro) else o.centro::VARCHAR end, '-',concat('0',o.nroorden))) AS nroordencentro,
				MIN(nrodoc) AS nrodocafil,
				MIN(barra) AS barraafil,
				o.nroorden AS nroorden,
				o.centro AS centro,
				MIN(date(ptutilizado)) AS fechaconsumo,
				MIN(p.pnombrefantasia) AS nombreprestador,
				MIN(case when (pg.pnombrefantasia IS NULL) THEN uwg.uwgdescripcion ELSE pg.pnombrefantasia END) AS nombregestor,
				MIN(p.pcuit)  AS cuitprestador,
				MIN(case when (pg.pcuit IS NULL) THEN uwg.idusuarioweb::text ELSE pg.pcuit END)  AS idgestor,
				MIN(case when (pra.pdescripcion IS NULL) THEN ct.ctdescripcion ELSE pra.pdescripcion END)  AS pdescripcion,
                SUM(case when (it.cantidad IS NULL) THEN 1 ELSE it.cantidad END)  AS cantidad
					FROM w_persona_token_info AS pti
						NATURAL JOIN prestador AS p
						JOIN persona_token as pk USING (idpersonatoken) 
						JOIN persona USING (nrodoc) 
						LEFT JOIN w_usuarioprestador AS up ON (up.idusuarioweb = pti.idusuariowebgestor)
						LEFT JOIN prestador AS pg ON (pg.idprestador = up.idprestador)
						LEFT JOIN w_usuariowebgestor AS uwg ON (uwg.idusuarioweb = pti.idusuariowebgestor)
						JOIN recibo_token rt USING (pttoken)
                        -- SL 04/04/24 - Agrego condicion para buscar la orden en caso de que haya un recibo > muchas ordenes
                        JOIN ordenrecibo orc ON (orc.idrecibo = rt.idrecibo AND orc.centro = rt.centro AND (length(pk.pttoken) >= 6 AND pk.pttoken ilike concat(orc.nroorden, orc.centro, '%')))
						JOIN orden as o ON (o.nroorden = orc.nroorden AND o.centro = orc.centro)
						JOIN comprobantestipos AS ct ON(o.tipo=ct.idcomprobantetipos)						
						LEFT JOIN itemvalorizada AS itv ON (itv.nroorden = orc.nroorden AND itv.centro = orc.centro)
						LEFT JOIN item it ON (it.iditem = itv.iditem AND it.centro = itv.centro)
						LEFT JOIN practica as pra ON (pra.idnomenclador = it.idnomenclador AND pra.idcapitulo = it.idcapitulo AND pra.idsubcapitulo = it.idsubcapitulo AND pra.idpractica = it.idpractica)
				WHERE (pti.idprestador = vidprestador OR pti.idusuariowebgestor = CAST(parametro->>'idusuariowebgestor' AS BIGINT)) AND NOT nullvalue(pk.ptutilizado)
                GROUP BY o.nroorden, o.centro 
				ORDER BY MIN(ptutilizado) DESC
				--LIMIT 50
				) as t;
			IF FOUND THEN
				respuestajson_info = rdatos.data;
				respuestajson = respuestajson_info;
		END IF;
	END IF;
	IF (parametro ->> 'accion' = 'filtrar') THEN
		SELECT INTO rdatos  array_to_json(array_agg(row_to_json(t))) AS data
			FROM (
			SELECT MIN(concat(apellido,', ',nombres)) as afiliado, 
				MIN(concat(case when (o.centro < 10) then concat('0',o.centro) else o.centro::VARCHAR end, '-',concat('0',o.nroorden))) AS nroordencentro,
				MIN(nrodoc) AS nrodocafil,
				MIN(barra) AS barraafil,
				o.nroorden AS nroorden,
				o.centro AS centro,
				MIN(date(ptutilizado)) AS fechaconsumo,
				MIN(p.pnombrefantasia) AS nombreprestador,
				MIN(case when (pg.pnombrefantasia IS NULL) THEN uwg.uwgdescripcion ELSE pg.pnombrefantasia END) AS nombregestor,
				MIN(p.pcuit)  AS cuitprestador,
				MIN(case when (pg.pcuit IS NULL) THEN uwg.idusuarioweb::text ELSE pg.pcuit END)  AS idgestor,
				MIN(case when (pra.pdescripcion IS NULL) THEN ct.ctdescripcion ELSE pra.pdescripcion END)  AS pdescripcion,
                SUM(case when (it.cantidad IS NULL) THEN 1 ELSE it.cantidad END)  AS cantidad
				FROM w_persona_token_info AS pti
					NATURAL JOIN prestador AS p
					JOIN persona_token as pk USING (idpersonatoken) 
					JOIN persona USING (nrodoc) 
					LEFT JOIN w_usuarioprestador AS up ON (up.idusuarioweb = pti.idusuariowebgestor)
					LEFT JOIN prestador AS pg ON (pg.idprestador = up.idprestador)
					LEFT JOIN w_usuariowebgestor AS uwg ON (uwg.idusuarioweb = pti.idusuariowebgestor)
					JOIN recibo_token rt USING (pttoken)
                    -- SL 04/04/24 - Agrego condicion para buscar la orden en caso de que haya un recibo > muchas ordenes
                    JOIN ordenrecibo orc ON (orc.idrecibo = rt.idrecibo AND orc.centro = rt.centro AND (length(pk.pttoken) >= 6 AND pk.pttoken ilike concat(orc.nroorden, orc.centro, '%')))					JOIN orden as o ON (o.nroorden = orc.nroorden AND o.centro = orc.centro)
					JOIN comprobantestipos AS ct ON(o.tipo=ct.idcomprobantetipos)						
					LEFT JOIN itemvalorizada AS itv ON (itv.nroorden = orc.nroorden AND itv.centro = orc.centro)
					LEFT JOIN item it ON (it.iditem = itv.iditem AND it.centro = itv.centro)
					LEFT JOIN practica as pra ON (pra.idnomenclador = it.idnomenclador AND pra.idcapitulo = it.idcapitulo AND pra.idsubcapitulo = it.idsubcapitulo AND pra.idpractica = it.idpractica)
                    --SL 03/04/24 - Agrego nullvalue
			WHERE (pti.idprestador = vidprestador OR pti.idusuariowebgestor = CAST(parametro->>'idusuariowebgestor' AS BIGINT)) AND NOT nullvalue(pk.ptutilizado)
			AND
			((parametro->>'filtroord' = '-1') OR (parametro->>'filtroord' <> '-1' AND (p.pcuit = parametro->>'filtroord' OR pg.pcuit = parametro->>'filtroord' OR uwg.idusuarioweb = parametro->>'filtroord')))
			AND
			((parametro->>'filtroordafil' = '-1') OR (parametro->>'filtroordafil' <> '-1' AND (nrodoc = parametro->>'filtroordafil')))
			AND date(ptutilizado) 
			BETWEEN parametro->> 'fechaini' AND parametro->> 'fechafin'
            GROUP BY o.nroorden, o.centro 
			ORDER BY MIN(ptutilizado) DESC
			) as t;
		IF FOUND THEN
			respuestajson_info = rdatos.data;
			respuestajson = respuestajson_info;
		END IF;
	END IF;
	RETURN respuestajson;
END;
$function$
