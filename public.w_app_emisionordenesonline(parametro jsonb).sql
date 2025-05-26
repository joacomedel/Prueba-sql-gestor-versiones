CREATE OR REPLACE FUNCTION public.w_app_emisionordenesonline(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*	
SELECT * FROM w_app_emisionordenesonline('
		{
            "NroAfiliado": 43947118,
			"NroDocTitu": null,
            "Barra": 32,
            "contexto_atencion": "Ambulatorio",
            "NroDocumento": 43947118,
            "TipoDoc": 1,
            "Track": null,
            "ApellidoEfector": "",
            "NombreEfector": "",
            "CuilEfector": "30590509643",
            "token": null,
            "info_consumio_token": "app",
            "FechaConsumo": '2023-07-26',
            "Diagnostico": "",
            "MatriculaEfector": "",
            "CategoriaEfector": "",
            "ConsumosWeb": [{ "Cantidad": 1, "CodigoConvenio": "12.42.01.01", "DescripcionCodigoConvenio": "Consulta General" }],
        };
')
*/
DECLARE
       respuestajson jsonb;
       respuestajsontk jsonb;
       respuestaasiento public.facturaventa%rowtype;
       nroDocFac VARCHAR;
       nroorden bigint;
       centro integer;
BEGIN
	--Borro tabla creada en "expendio_asentarfacturaventa_global" para que no moleste
	IF iftableexists('temporden') THEN
		DROP TABLE temporden;
	END IF;

	--Emito la orden
    SELECT INTO respuestajson w_emitirconsumoafiliado(parametro);
	
	-- Creo temporal para realizar deuda en Cta Cte o borro sus datos
	IF NOT  iftableexists('temp_recibocliente') THEN
		CREATE TEMP TABLE temp_recibocliente (
			idrecibo bigint,
			centro INTEGER,
			nrodoc VARCHAR,
			tipodoc INTEGER,
			nrosucursal INTEGER,
			tipofactura VARCHAR,
			idformapagotipos INTEGER DEFAULT null,
			fechafactura DATE,
			accion VARCHAR);
	ELSE
		DELETE FROM temp_recibocliente;
	END IF;
	-- Verifico si es titular o beneficiario
	IF nullvalue(parametro->>'NroDocTitu') THEN
		nroDocFac = parametro->>'NroDocumento';
	ELSE
		nroDocFac = parametro->>'NroDocTitu';
	END IF;

/*  -- SL 07/11/23 - Comento ya que se utiliza para generar la factura
	-- Inserto
	INSERT INTO temp_recibocliente(idrecibo, centro, nrodoc, tipodoc, accion, fechafactura)  
		VALUES (
			(respuestajson->>'idrecibo')::bigint,
			(respuestajson->>'centro')::integer,
			(nroDocFac)::VARCHAR,
			(parametro->>'TipoDoc')::integer,
			'autogestion',  -- Valor fijo
			current_date  -- Valor fijo
		);

	--Borro tabla creada en "w_generar_orden_consumoafiliado" para que no moleste
	DROP TABLE temporden;
*/

	-- Genero la factura en cta cte
	--- Vas 011123 se comenta para no generar automaticamente la factura
        --- SELECT INTO respuestaasiento * FROM expendio_asentarfacturaventa_global();

        -- SL 07/11/23 - Creo el pendiente para facturacion
          nroorden := (respuestajson->>'nroorden')::bigint;
          centro := (respuestajson->>'centro')::integer;
          PERFORM expendio_cambiarestadoorden(nroorden, centro, 9);


    return respuestajson;

END;$function$
