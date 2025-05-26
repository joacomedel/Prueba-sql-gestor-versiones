CREATE OR REPLACE FUNCTION public.cargarordenesfacturaobserver(params jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$

DECLARE
	respuesta JSONB;
	/* Params
	- NroCaratula
	- NroRegistro
	- PrestadorFactura
	*/
	caratula CHARACTER VARYING;
	registro CHARACTER VARYING;
	vnroorden BIGINT;
	vnrorecetario CHARACTER VARYING;
	vcentro INTEGER;
	crecetario REFCURSOR;
	creceta REFCURSOR;
	ritem RECORD;
	rreceta RECORD;
	diffimportes INTEGER;
	vidprestador BIGINT;

BEGIN

	caratula = params->>'NroCaratula';
	registro = params->>'NroRegistro';
	vidprestador = params->>'PrestadorFactura';
	respuesta = '{}'::JSONB;

	/*********************** Temporales ***********************/

	CREATE TEMP TABLE ttordenesgeneradas(
		nroorden   BIGINT,
		centro     INT4
	) WITHOUT OIDS;

	CREATE TEMP TABLE IF NOT EXISTS ttorden(
		nrodoc VARCHAR(8),
		tipodoc INT NOT NULL,
		numorden BIGINT,
		ctroorden INTEGER,
		centro INT4 NOT NULL,
		idasocconv BIGINT,
		recibo BOOLEAN,
		cantordenes INT4,
		tipo INT8,
		amuc FLOAT,
		efectivo FLOAT,
		debito FLOAT,
		credito FLOAT,
		cuentacorriente FLOAT,
		sosunc FLOAT,
		importeenletras VARCHAR
	) WITHOUT OIDS;

	CREATE TEMP TABLE IF NOT EXISTS temprecetarioitem(
		nrorecetario INTEGER NOT NULL,
		centro INTEGER NOT NULL,
		mnroregistro INTEGER NOT NULL,
		nomenclado BOOLEAN NOT NULL,
		idmotivodebito INTEGER,
		importe DOUBLE PRECISION,
		importeapagar DOUBLE PRECISION,
		ridebito DOUBLE PRECISION,
		importevigente DOUBLE PRECISION,
		coberturaporplan REAL,
		coberturaefectiva REAL
	) WITHOUT OIDS;

	CREATE TEMP TABLE IF NOT EXISTS ttconsulta(idplancobertura VARCHAR) WITHOUT OIDS;

	/*********************** Crear ordenes ***********************/

	-- Buscar cada receta a cargar de la caratula
	OPEN creceta FOR SELECT roopf, ronroafiliado, idprestador
				FROM caratulaobserver
					INNER JOIN recetaobserver ON coopf = roopf
					INNER JOIN mapeoprestadorobserver USING (coidfarmacia)
					INNER JOIN prestador USING (idprestador)
				WHERE conrocaratula = caratula
				GROUP BY roopf, ronroafiliado, idprestador;
	FETCH creceta INTO rreceta;	
	WHILE FOUND LOOP

		-- Para cada receta se crea una orden (de tipo recetario)
		DELETE FROM ttorden;
		INSERT INTO ttorden(
			nrodoc,
			tipodoc,
			centro,
			idasocconv,
			recibo,
			cantordenes,
			tipo,
			amuc,
			efectivo,
			debito,
			credito,
			cuentacorriente,
			sosunc,
			importeenletras)
		VALUES(
			SUBSTRING(rreceta.ronroafiliado FROM 1 FOR 8),
			1,
			centro(),
			95, -- asocconvenio
			FALSE, -- Hardcode
			NULL, 
			4, -- Hardcode
			0, -- Desuso
			0, -- Desuso
			0, -- Desuso
			0, -- Desuso
			0, -- Desuso
			0, -- Desuso
			'' -- Desuso
			);

		DELETE FROM ttconsulta;
		INSERT INTO ttconsulta VALUES('15');

		PERFORM asentarconsultarecibo() AS valor;

		SELECT nroorden,centro
		INTO vnrorecetario, vcentro FROM ttordenesgeneradas;
		vnroorden = vnrorecetario; -- El numero de orden es igual al numero de recetario

		/*********************** Cargar item ***********************/

		-- Buscar la info de cada item autorizado de la receta
		OPEN crecetario FOR SELECT * FROM caratulaobserver
								JOIN recetaobserver ON (coopf = roopf)
								JOIN medicamento ON (mcodbarra = rocodbarras)
								NATURAL JOIN manextra
								NATURAL JOIN monodroga
								NATURAL JOIN plancoberturafarmacia
								NATURAL JOIN valormedicamento
                                LEFT JOIN LATERAL (
                                            SELECT (porccob * 100) AS porccob, pcdescripcion, idplancobertura
                                            FROM far_traercoberturasarticuloafiliado_validador_(CAST(idmonodroga AS CHARACTER VARYING), NULL, CAST(SUBSTRING(ronroafiliado FROM 1 FOR 8) AS BIGINT), NULL, NULL, NULL, rofechaventa)
                                ) AS planesparaafiliado ON porccob = roporcentajecobertura
								WHERE conrocaratula = caratula
										AND ((vmfechaini::DATE <= rofechaprescripcion)
										AND (
											vmfechafin IS NULL
											OR vmfechafin::DATE > rofechaprescripcion
										))
										AND ((fechainivigencia::DATE <= now())
										AND (
											fechafinvigencia IS NULL
											OR fechafinvigencia::DATE > now()
										))
										AND roautorizada = 'S' -- Verificar que esta autorizada
										AND coopf = rreceta.roopf; 
		FETCH crecetario INTO ritem;
		WHILE FOUND LOOP

			-- Cargar cada item
			UPDATE recetario
			SET fechauso = ritem.rofechaventa,
				nrodoc = SUBSTRING(ritem.ronroafiliado FROM 1 FOR 8), 
				tipodoc = 1,
				idprestador = '8707', -- ID de medico prestador sin definir 
				nroregistro = CAST(registro AS INTEGER),
				anio = EXTRACT(YEAR FROM NOW())
			WHERE nrorecetario = vnrorecetario AND centro = vcentro;

			diffimportes = ritem.roimporteosrenglon - ritem.vmimporte*ritem.rocantidad;

			DELETE FROM temprecetarioitem;
			INSERT INTO temprecetarioitem(	nrorecetario,
											centro,
											mnroregistro,
											nomenclado,
											idmotivodebito,
											importe,
											importeapagar, 
											ridebito, 
											importevigente,	
											coberturaporplan, 
											coberturaefectiva)
								VALUES (	CAST(vnrorecetario AS INTEGER),
											ritem.idcentroinformacionobserver,
											ritem.mnroregistro,
											ritem.nomenclado, 
											CASE WHEN diffimportes > 0 THEN 54 /* Diferencia valor */ ELSE NULL END,
											ritem.roimporteosrenglon,
											ritem.roimporteosrenglon, 
											CASE WHEN diffimportes > 0 THEN diffimportes ELSE 0.00 END, 
											ritem.vmimporte,
											ritem.multiplicador * 100,
											CASE WHEN ritem.porccob IS NOT NULL THEN ritem.porccob ELSE CAST(ritem.roporcentajecobertura AS REAL) END -- porccob
                                        );

			SELECT idprestador INTO vidprestador 
			FROM mapeoprestadorobserver
			WHERE coidfarmacia = ritem.coidfarmacia;

			INSERT INTO fichamedicapreauditada_fisica(
						idfichamedicaitem, 
						idcentrofichamedicaitem, 
						fmpaporeintegro, 
						idfichamedicapreauditada,
						idcentrofichamedicapreauditada,
						idauditoriaodontologiacodigo,
						idnomenclador,
						idcapitulo, 
						idsubcapitulo, 
						idpractica,
						fmpacantidad,
						fmpaidusuario, 
						fmpafechaingreso,
						iditem,
						centro, 
						nroregistro, 
						anio, 
						idfichamedicapreauditadaodonto, 
						idcentrofichamedicapreauditadaodonto, 
						idpiezadental, 
						idletradental, 
						idzonadental, 
						idfichamedicaitemodonto, 
						idcentrofichamedicaitemodonto, 
						nroorden, 
						nrodoc,
						tipodoc, 
						idprestador, 
						idauditoriatipo,
						fechauso,
						importe, 
						idplancobertura, 
						fmpadescripcion, 
						fmpaifechaingreso,
						fmpaiimportes, 
						fmpaiimporteiva,
						fmpaiimportetotal, 
						descripciondebito,
						importedebito, 
						idmotivodebitofacturacion,
						tipo)
			VALUES (	NULL, 
						NULL, 
						FALSE, 
						NULL, -- Secuencia
						NULL,
						0, -- Hardcode
						'98', -- Hardcode
						'01', -- Hardcode
						'01', -- Hardcode
						'01', -- Hardcode
						ritem.rocantidad,
						250,
						NULL, -- Seq
						ritem.mnroregistro,
						centro(),
						CAST(registro AS BIGINT),
						EXTRACT(YEAR FROM NOW()), 
						NULL, -- Seq
						NULL, -- Seq
						NULL, -- Desuso
						NULL, -- Desuso
						NULL, -- Desuso
						NULL, -- Desuso
						NULL, -- Desuso
						vnroorden,
						SUBSTRING(ritem.ronroafiliado FROM 1 FOR 8),
						1,
						vidprestador, -- idprestador
						3, 
						ritem.rofechaventa, 
						NULL, 
						CASE WHEN ritem.idplancobertura IS NOT NULL THEN ritem.idplancobertura ELSE 15 END,  -- idplancobertura
						CASE WHEN ritem.pcdescripcion IS NOT NULL THEN ritem.pcdescripcion ELSE 'AUDITAR' END, -- pcdescripcion
						NULL,
						ritem.roimporteosrenglon, -- fmpaiimportes
						NULL,
						ritem.roimporteos, -- fmpaiimportetotal
						NULL,
						CASE WHEN diffimportes > 0 THEN diffimportes ELSE 0.00 END, -- importedebito
						NULL,
						14 -- Hardcode tabla comprobantestipos
					);

			PERFORM alta_modifica_preauditoria_odonto_v1(CAST(vnrorecetario AS BIGINT), vcentro);
            FETCH crecetario INTO ritem;
		END LOOP;
		CLOSE crecetario;

    	FETCH creceta INTO rreceta;	
	END LOOP;
	CLOSE creceta;

	respuesta = respuesta::JSONB || jsonb_build_object('NroCaratula', caratula);

	RETURN respuesta;

END;

$function$
