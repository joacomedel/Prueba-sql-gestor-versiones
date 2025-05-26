CREATE OR REPLACE FUNCTION public.w_determinardeudactacte(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"NroDocumento":"08216252","TipoDocumento":1}
*/
DECLARE
--VARIABLES 
   vmontoctacte DOUBLE PRECISION;
--RECORD
      respuestajson jsonb;
      rpersona RECORD;
      rafiliado  RECORD;
      rformapagouw RECORD;
begin
	IF nullvalue(parametro->>'NroDocumento') AND nullvalue(parametro->>'TipoDocumento')  THEN 
		RAISE EXCEPTION 'R-001, Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;
	-- SL 08/11/23 - Agrego condicion para verificar si NO vengo desde la APP
	IF (not nullvalue(parametro->>'uwnombre') AND parametro->>'uwnombre' <> 'ususm') THEN
		select into respuestajson row_to_json(deudactacte) 
		from (
		select  array_to_json(array_agg(row_to_json(t))) as deuda
			from ( 
			select *,split_part(denominacion,',',1) as apellido,split_part(denominacion,',',2) as nombre  
				from ctactedeudacliente
			natural join clientectacte
				NATURAL JOIN cliente  
				--MaLaPi 03-08-2021 Por pedido de Maricel, solo se puede pagar por la web, deuda de aporte de Jubilados
			where nrocuentac = 10826 and saldo > 0
				and nrocliente = parametro->>'NroDocumento'
				) as t
		) as  deudactacte;
	ELSE
		--SL 24/05/24 - Agrego condicion que si supera las 24hs y no se encuentra bloqueada se libera la deuda
		PERFORM w_cambiarestadodeuda(json_build_object('iddeuda', ccdc.iddeuda,'idcentrodeuda', ccdc.idcentrodeuda, 'deudatabla', 'cuentacorrientedeuda', 'idctactedeudaclienteestadotipo', 2, 'idusuarioweb', 5600)::jsonb) 
		FROM cuentacorrientedeuda ccdc
			LEFT JOIN cuentacorrientedeudaestado ccdce ON (ccdce.iddeuda = ccdc.iddeuda AND ccdce.idcentrodeuda = ccdc.idcentrodeuda)
		WHERE  saldo > 0 
			AND nullvalue(fechaenvio) 
			AND idctacte = concat(parametro->>'NroDocumento', parametro->>'TipoDocumento')
			AND nullvalue(ccdefechafin)
			AND (ccdefechaini + INTERVAL '24 HOURS') <= CURRENT_TIMESTAMP
			AND (idctactedeudaclienteestadotipo <> 1 AND idctactedeudaclienteestadotipo <> 2);

		PERFORM  w_cambiarestadodeuda(json_build_object('iddeuda', ctctdc.iddeuda,'idcentrodeuda', ctctdc.idcentrodeuda, 'deudatabla', 'ctactedeudacliente', 'idctactedeudaclienteestadotipo', 2, 'idusuarioweb', 5600)::jsonb) 
		FROM ctactedeudacliente ctctdc
			NATURAL JOIN clientectacte
			NATURAL JOIN cliente  
			LEFT JOIN ctactedeudaclienteestado ctctdce ON (ctctdce.iddeuda = ctctdc.iddeuda AND ctctdce.idcentrodeuda = ctctdc.idcentrodeuda)
		WHERE saldo > 0 
			AND nrocliente = parametro->>'NroDocumento' 
			AND nullvalue(ctctdefechafin)
			AND (ctctdefechaini + INTERVAL '24 HOURS') <= CURRENT_TIMESTAMP
			AND (idctactedeudaclienteestadotipo <> 1 AND idctactedeudaclienteestadotipo <> 2);

		--SL 09/11/23 - Agrego UNION para contemplar deudas de ordenes de jubilado desde la APP
		select into respuestajson row_to_json(deudactacte) 
			from (
				select  array_to_json(array_agg(row_to_json(t))) as deuda
					from ( 
						SELECT ccdc.iddeuda, ccdc.idcentrodeuda, fechamovimiento, nrocliente, barra, 'cuentacorrientedeuda' AS deudatabla, movconcepto, idcomprobante, 
						idctactedeudaclienteestadotipo, idcuentacorrientedeudaestado, ccdefechafin,
						importe, saldo, nrocuentac, split_part(denominacion,',',1) AS apellido,split_part(denominacion,',',2) AS nombre 
							FROM cuentacorrientedeuda ccdc
							JOIN cliente ON (nrodoc = nrocliente AND tipodoc = barra) 
							LEFT JOIN cuentacorrientedeudaestado ccdce ON (ccdce.iddeuda = ccdc.iddeuda AND ccdce.idcentrodeuda = ccdc.idcentrodeuda AND nullvalue(ccdefechafin))
						WHERE  saldo > 0 AND idctacte = concat(parametro->>'NroDocumento', parametro->>'TipoDocumento') AND nullvalue(fechaenvio)  AND (idctactedeudaclienteestadotipo <> 1 OR nullvalue(idctactedeudaclienteestadotipo))
							UNION
						SELECT ccdc.iddeuda, ccdc.idcentrodeuda, fechamovimiento, nrocliente, barra, 'ctactedeudacliente' AS deudatabla, movconcepto, idcomprobante, 
						idctactedeudaclienteestadotipo, idctactedeudaclienteestado, ctctdefechaini,
						importe, saldo, nrocuentac, split_part(denominacion,',',1) as apellido,split_part(denominacion,',',2) as nombre  
							FROM ctactedeudacliente ccdc
							NATURAL JOIN clientectacte
							NATURAL JOIN cliente  
							LEFT JOIN ctactedeudaclienteestado ccdce ON (ccdce.iddeuda = ccdc.iddeuda AND ccdce.idcentrodeuda = ccdc.idcentrodeuda AND nullvalue(ctctdefechafin))
						WHERE saldo > 0 AND nrocliente = parametro->>'NroDocumento' AND (idctactedeudaclienteestadotipo <> 1 OR nullvalue(idctactedeudaclienteestadotipo))
					) as t
                               WHERE fechamovimiento >= '2023-01-01'  -- SL 22-11-23 - Agrego condicion para traer deudas de este año
			) as  deudactacte;

	END IF;
		return respuestajson;

	end;
	
$function$
