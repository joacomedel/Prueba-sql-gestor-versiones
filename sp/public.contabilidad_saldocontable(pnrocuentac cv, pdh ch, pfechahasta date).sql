CREATE OR REPLACE FUNCTION public.contabilidad_saldocontable(pnrocuentac character varying, pdh character, pfechahasta date)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$ 
DECLARE
	saldo double precision;
BEGIN 
	SELECT sum(acimonto) into saldo
	FROM asientogenericoitem AR 
	NATURAL JOIN asientogenerico AE 	

  -- Agrega VAS 30/03/2022
 NATURAL JOIN (select * from asientogenericoestado where nullvalue(agefechafin) and tipoestadofactura<>5) estado	
-- Agrega VAS 30/03/2022		
	WHERE acid_h=pdh
		AND AR.nrocuentac=pnrocuentac
		AND AE.agfechacontable< pfechahasta
                AND AE.agfechacontable>='2019-01-01'::date;  --vas 23-03-2022 para que solo tome los movimientos que se generaron en SIGES
RETURN saldo;
END;
$function$
