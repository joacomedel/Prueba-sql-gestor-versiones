CREATE OR REPLACE FUNCTION public.calcularmontodispcuentacorriente(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
Dado el nrodoc, tipodoc calcula el monto disponible en la cuentacorriente.
SELECT calcularmontodispcuentacorriente('{nrodoc = 28272137, tipodoc = 1}');


SELECT * FROM calcularmontodispcuentacorriente('{nrodoc = 27091730, tipodoc = 1}');
*/
DECLARE
	alta refcursor;
 	rfiltros RECORD;
 	rexcentos RECORD;
 	verifica RECORD;
        elem RECORD;
        montodisponibleactual RECORD;
        resultado varchar;
        vimportedeuda double precision;
        vimportepago double precision;
        montodeudasacumuladas double precision;
	
	
BEGIN
-- BelenA subido el 06-05-2024
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
rfiltros.nrodoc = trim(rfiltros.nrodoc);

		-- Obtengo el importe de las deudas hasta el dia 22 del mes actual
		SELECT INTO vimportedeuda sum(saldo) as saldo 
		FROM cuentacorrientedeuda 
		WHERE nrodoc = rfiltros.nrodoc::varchar
		AND fechamovimiento <= now()  -- BelenA Estaba comentado, se descomento el 09-12-24 porque estaba teniendo en cuenta deudas futuras
		AND saldo > 0;

		IF nullvalue(vimportedeuda) THEN
		   vimportedeuda = 0;
		END IF;

		--RAISE NOTICE 'vimportedeuda: (%)', vimportedeuda;

		-- Obtengo el importe de los pagos que realizo el afiliado, ya que pueden utilizarse para saldar las deudas y aun no se han realizado las imputaciones
		SELECT INTO vimportepago sum(abs(saldo)) as saldo 
		FROM cuentacorrientepagos 
		WHERE saldo <> 0 and nrodoc = rfiltros.nrodoc::varchar;

		IF nullvalue(vimportepago) THEN
		   vimportepago = 0;
		END IF;

		--RAISE NOTICE 'vimportepago: (%)', vimportepago;

		montodeudasacumuladas =  vimportedeuda - vimportepago;

		--RAISE NOTICE 'Monto consumido por el afiliado nrodoc: (%), monto: (%)', rfiltros.nrodoc, montodeudasacumuladas;

		-- Veo si es un empleado de sosunc con saldo disponible
		SELECT INTO verifica * 
		FROM ctasctesmontosdescuento 
		WHERE nrodoc = rfiltros.nrodoc AND nullvalue(ccmdfechafin) AND ccmdimporte >= 0;

		IF FOUND THEN	
			-- Si es empleado de sosunc	
			SELECT into montodisponibleactual  *
			FROM ctasctesmontosdescuento 
			WHERE idctasctesmontosdescuento = verifica.idctasctesmontosdescuento 
			AND idcentroctasctesmontosdescuento = verifica.idcentroctasctesmontosdescuento;

			-- Esto me deberia devolver el disponible menos el monto de las deudas acumuladas
			resultado = concat(( montodisponibleactual.ccmdimporte - montodeudasacumuladas ) :: varchar,',true');

		ELSE
			-- Si no es empleado
			resultado = concat(montodeudasacumuladas,',false');
		--	RAISE NOTICE 'Dentro del ELSE, no es empleadoooo : (%), monto: (%)', resultado, montodeudasacumuladas;

		END IF;

		--RAISE NOTICE 'resultado de resta montodisponibleactual.ccmdimporte - montodeudasacumuladas: (%), montodeudasacumuladas: (%)', resultado, montodeudasacumuladas;


--		RAISE EXCEPTION 'Monto consumido por el afiliado nrodoc: (%), monto: (%)', rfiltros.nrodoc, montodeudasacumuladas;

return resultado;
END;
$function$
