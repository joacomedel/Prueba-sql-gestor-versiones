CREATE OR REPLACE FUNCTION public.w_obtenerprestadoresafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
 /* SELECT * FROM public.w_obtenerprestadoresafiliado('{ "nrodoc":"1234"}')*/
DECLARE	
	respuestajson jsonb;
	prestadoresafiliado jsonb;
	rafiliado RECORD;
	
	vnrodoc varchar;
BEGIN
	vnrodoc = parametro ->> 'nrodoc' ;
	
	IF vnrodoc IS NULL THEN
		RAISE EXCEPTION 'R-001 WS_obtenerprestadoresafil, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;
	
	SELECT INTO rafiliado nrodoc FROM public.persona WHERE nrodoc = vnrodoc;
	IF NOT FOUND THEN
		RAISE EXCEPTION	'R-002 WS_obtenerprestadoresafil, Usuario inválido! Inténtelo nuevamente o comuníquese con soporte.';
	END IF;

	SELECT INTO prestadoresafiliado json_agg(auxPrestadores) FROM (
		SELECT * FROM (
			SELECT DISTINCT ON (idprestador) idprestador, fechauso,fechaauditoria, nroorden,centro,tipo,descripcion, nombrefantasia, especialidad FROM (

				SELECT * FROM (
					SELECT DISTINCT ON (o.idprestador) o.idprestador, o.fechauso, o.fechaauditoria, o.nroorden, o.centro, o.tipo, p.pdescripcion AS descripcion, p.pnombrefantasia AS nombreFantasia, m.mespecialidad as especialidad
					FROM consumo NATURAL JOIN orden	INNER JOIN ordenesutilizadas AS o USING (nroorden,centro,tipo)
					NATURAL JOIN prestador AS p LEFT JOIN w_valoracion AS v USING (nroorden,centro,tipo) LEFT JOIN matricula AS m ON m.idprestador = p.idprestador
						LEFT JOIN (
							SELECT DISTINCT ON (idprestador) idprestador, fechauso
								from ordenesutilizadas
								NATURAL JOIN w_valoracion
								WHERE nrodocuso = vnrodoc
								ORDER BY idprestador, fechauso DESC, fechaauditoria DESC
						) AS ultAteValoradaPrest ON o.idprestador = ultAteValoradaPrest.idprestador
					WHERE NOT anulado and nrodocuso = vnrodoc AND v.nroorden IS NULL AND v.centro IS NULL AND v.tipo IS NULL AND (o.fechauso > ultAteValoradaPrest.fechauso OR ultAteValoradaPrest.fechauso IS NULL)					
						AND NOT p.pdescripcion ilike '%Sin Definir%' AND tipo <> 56 -- sl 11/08/23 - Agrego para evitar los tipo 56, ya que no tiene prestadores al generar la orden por la app y se ve como; prestador'SOSUNC'
					ORDER BY o.idprestador, o.fechauso DESC, o.nroorden DESC
				) AS ultimaatencionsinvalorizar

				UNION

				SELECT * FROM (
					SELECT DISTINCT ON (p.idprestador) p.idprestador, (fechaemision::date) AS fechauso, fechaemision AS fechaauditoria, o.nroorden, o.centro, o.tipo, p.pdescripcion AS descripcion, p.pnombrefantasia AS nombreFantasia, m.mespecialidad AS especialidad
						FROM consumo NATURAL JOIN orden AS o JOIN ordvalorizada USING(nroorden,centro) JOIN prestador AS p ON p.idprestador = nromatricula
						LEFT JOIN matricula AS m ON p.idprestador = m.nromatricula LEFT JOIN ordenesutilizadas AS uso USING(nroorden,centro,tipo)
						LEFT JOIN w_valoracion AS v USING(nroorden,centro,tipo)
						LEFT JOIN (
							SELECT DISTINCT ON (p.idprestador) p.idprestador, fechaemision AS fechauso
								FROM consumo
									NATURAL JOIN orden
									JOIN ordvalorizada USING(nroorden,centro)
									JOIN prestador AS p  ON p.idprestador = nromatricula
									LEFT JOIN matricula AS m ON m.idprestador = p.idprestador
									LEFT JOIN ordenesutilizadas AS uso USING(nroorden,centro,tipo)
									JOIN w_valoracion USING(nroorden,centro,tipo)
									WHERE nullvalue(uso.nroorden) AND NOT anulado AND nrodoc = vnrodoc /*AND tipo = 56*/
						) AS ultAteValoradaPrest ON p.idprestador = ultAteValoradaPrest.idprestador
						WHERE NOT anulado AND nrodoc = vnrodoc AND v.nroorden IS NULL AND v.centro IS NULL AND v.tipo IS NULL AND (fechaemision > ultAteValoradaPrest.fechauso OR ultAteValoradaPrest.fechauso IS NULL) AND NOT anulado
							AND NOT p.pdescripcion ilike '%Sin Definir%' AND tipo <> 56 -- sl 11/08/23 - Agrego para evitar los tipo 56, ya que no tiene prestadores al generar la orden por la app y se ve como; prestador'SOSUNC'
						ORDER BY p.idprestador, fechaemision DESC, nroorden DESC
				) AS ultimaatencionvalorizada

			) AS prestadoresFinales
			WHERE extract(year from fechauso) >= extract(year from CURRENT_DATE) - 1 --Se extraen las atenciones del año actual y los N anteriores.
			ORDER BY idprestador, fechauso DESC, fechaauditoria DESC
			LIMIT 6
		) AS aux
		ORDER BY fechauso DESC, fechaauditoria DESC
	) AS auxPrestadores;

	IF prestadoresafiliado IS NOT NULL THEN
		respuestajson = concat('{"prestadores":', prestadoresafiliado ,'}');
	ELSE
		respuestajson = '{"prestadores":[]}';
	END IF;

	RETURN respuestajson;
END$function$
