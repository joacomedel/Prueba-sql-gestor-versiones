CREATE OR REPLACE FUNCTION public.calcularmontosdisponibles(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
Dado el nrodoc, tipodoc calcula los montos disponibles y los pone en la informacion de ctas.ctes.
SELECT calcularmontosdisponibles('{nrodoc = 28272137, tipodoc = 1}');
*/
DECLARE
	alta refcursor;
 	rfiltros RECORD;
 	rexcentos RECORD;
 	verifica RECORD;
        elem RECORD;
        resultado varchar;
        vimportedeuda double precision;
        vimportepago double precision;
	
	
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
rfiltros.nrodoc = trim(rfiltros.nrodoc);

SELECT INTO verifica * FROM ctasctesmontosdescuento WHERE nrodoc = rfiltros.nrodoc AND ccmdvigenciainicio<=current_date AND current_date<= ccmdvigenciafin AND ccmdimporte >= 0;
	IF FOUND THEN 
--            KR 04-12-19 No tiene sentido pq se updatea nuevamente luego de verificar la cta cte del afiliado
          --       UPDATE afilsosunc SET ctacteexpendio = ((verifica.ccmdimporte - verifica.ccmdmontoconsumido)>0)  WHERE nrodoc = rfiltros.nrodoc;

		SELECT INTO vimportedeuda sum(saldo) as saldo 
		FROM cuentacorrientedeuda 
		WHERE nrodoc = rfiltros.nrodoc
		AND fechamovimiento < date_trunc('MONTH', now()) + INTERVAL '22 day' --Toma solo las cuotas de los planes de pago que vencen este mes
		AND saldo <> 0;

		IF nullvalue(vimportedeuda) THEN
		   vimportedeuda = 0;
		END IF;


		SELECT INTO vimportepago sum(abs(saldo)) as saldo 
		FROM cuentacorrientepagos 
		WHERE saldo <> 0 and nrodoc = rfiltros.nrodoc;

		IF nullvalue(vimportepago) THEN
		   vimportepago = 0;
		END IF;

		RAISE NOTICE 'en if del calcularmontosdisponibles(%)', vimportepago;
		UPDATE ctasctesmontosdescuento SET ccmdmontoconsumido = vimportedeuda - vimportepago
		WHERE --nullvalue(ccmdfechafin) AND nrodoc = rfiltros.nrodoc;
                idctasctesmontosdescuento = verifica.idctasctesmontosdescuento AND idcentroctasctesmontosdescuento = verifica.idcentroctasctesmontosdescuento;
		--07-11-2018 MaLapi Pongo para que genere la alerta 
		PERFORM sys_generaralertactacteafiliado(rfiltros.nrodoc,1);
	      
		UPDATE afilsosunc SET ctacteexpendio = (verifica.ccmdimporte - (vimportedeuda - vimportepago)) > 0  WHERE nrodoc = rfiltros.nrodoc;

	ELSE 
	     UPDATE afilsosunc SET ctacteexpendio = false WHERE nrodoc = rfiltros.nrodoc;
	 
	END IF;


	--MaLapi 14-11-2018 Ahora verifico si esta en la tabla de excentos, pues si es asi, no hay que hacer ningun control.
	SELECT INTO rexcentos * FROM ctacteexentos WHERE nrodoc = rfiltros.nrodoc AND nullvalue(ccefechafin);
	IF FOUND THEN 
		IF rexcentos.ccetienen THEN --Independientemente de lo que digan la informacion, le vamos a habilitar la cta.cte
			UPDATE afilsosunc SET ctacteexpendio = true  WHERE nrodoc = rfiltros.nrodoc;

		ELSE --Independientemente de lo que digan la informacion, NO le vamos a habilitar la cta.cte
			UPDATE afilsosunc SET ctacteexpendio = false  WHERE nrodoc = rfiltros.nrodoc;

		END IF;
	END IF;
	--MaLapi Envio un varchar para que podamos mandar una estructura con la informacion que necesitemos en el futuro. 

resultado ='ok';
return resultado;
END;
$function$
