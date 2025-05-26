CREATE OR REPLACE FUNCTION public.w_app_traerordenemitidas(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    --RECORD
	rdatos RECORD;
	--VARIABLES
	respuestajson_info jsonb; 
	respuestajson jsonb;

BEGIN
	IF (parametro ->> 'nrodoc') IS NULL THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;
		SELECT INTO rdatos  array_to_json(array_agg(row_to_json(t)))
        FROM (
			SELECT concat(it.idnomenclador, it.idcapitulo, it.idsubcapitulo, it.idpractica) AS tipopractica, 
					concat (pt.nombres, ' ', pt.apellido) as nombreAfil,
					concat (pt.nrodoc, ' / ', pt.barra) as nroafil,
					o.nroorden, o.centro, o.tipo, o.idasocconv,
					ptk.ptfechaemision, ptk.ptfechavencimiento, ptk.pttoken,
					CASE WHEN nullvalue(it.iditem) THEN null ELSE concat(it.idnomenclador,'-',it.idcapitulo, '-',it.idsubcapitulo, '-',it.idpractica) END AS codigopractica,
					CASE WHEN (o.tipo = 56) THEN 'Sosunc Móvil' ELSE 'Obra Social' END AS lugaremision,
					CASE WHEN nullvalue(pra.pdescripcion) THEN cpt.ctdescripcion ELSE pra.pdescripcion END AS descripcion
			FROM orden o
				LEFT JOIN itemvalorizada USING (nroorden, centro)
				LEFT JOIN item it USING (iditem,centro)
				JOIN ordenrecibo orc USING (nroorden,centro)
				JOIN comprobantestipos cpt ON (o.tipo = cpt.idcomprobantetipos) 
				JOIN consumo ct ON (o.nroorden = ct.nroorden AND o.centro=ct.centro and ct.nrodoc= parametro->>'nrodoc')
				JOIN recibo_token rt on(rt.idrecibo = orc.idrecibo AND rt.centro = orc.centro AND rt.pttoken ilike concat(o.nroorden, '%'))
				JOIN persona pt ON (pt.nrodoc = ct.nrodoc)
				JOIN persona_token ptk on(ptk.pttoken = rt.pttoken)
                                LEFT JOIN ordenesutilizadas ou ON(ou.nroorden = o.nroorden AND ou.centro = o.centro)    --SL 09/05/25 - Agrego tabla para ver si esta utilizada la orden
				LEFT JOIN practica as pra ON (pra.idnomenclador = it.idnomenclador AND pra.idcapitulo = it.idcapitulo AND pra.idsubcapitulo = it.idsubcapitulo AND pra.idpractica = it.idpractica)
			WHERE 
				ct.nrodoc= parametro->>'nrodoc'
                                AND fechauso IS NULL    --SL 09/05/25 - Agrego condicion
				-- SL 02/05/24 - Filtro por ordenes de consulta y oftalmologica
				-- AND (tipo = 56 AND idasocconv = 154)
				--! SL 15/05/24 - trae las ordenes de expendio
				AND (
					idasocconv = 154 AND -- SOSUNC
						(
							o.tipo = 56 OR o.tipo = 4 OR (o.tipo = 2 AND ((it.idnomenclador = '12' AND it.idcapitulo = '46' AND it.idsubcapitulo = '00' AND it.idpractica = '01') 
																	OR (it.idnomenclador = '12' AND it.idcapitulo = '42' AND it.idsubcapitulo = '01' AND it.idpractica = '01')
																    )
													 )
						)
					)
				AND (o.tipo = 56 OR fechaemision >= '2024-06-13')		--! SL 15/05/24 - Descomentar y poner fecha de comunicacion para traer ordenes de sucursal
				AND not ct.anulado 
				AND nullvalue(ptutilizado)
				ORDER BY nroorden DESC
            ) as t;
	IF rdatos IS NOT NULL AND FOUND  THEN				
		respuestajson_info = concat('{ "datos":', row_to_json(rdatos), '}');
		respuestajson = respuestajson_info;
	ELSE
		respuestajson = '{"datos":[]}';
	END IF;
		
	RETURN respuestajson;
END;

$function$
