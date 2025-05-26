CREATE OR REPLACE FUNCTION public.dartextoinfocob(bigint, integer, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
    eltexto VARCHAR;
    latablapago VARCHAR; 
    latabladeudapago VARCHAR;
    latabladeuda VARCHAR;

BEGIN
/*Defino con que tabla debo joinear*/
         IF ($3=2 ) THEN 
          latablapago = 'ctactepagonoafil';
          latabladeudapago = 'ctactedeudapagonoafil';
          latabladeuda = 'ctactedeudanoafil';
         ELSE 
          latablapago = 'cuentacorrientepagos';
          latabladeudapago = 'cuentacorrientedeudapago';
          latabladeuda = 'cuentacorrientedeuda';
         END IF;

EXECUTE concat(' 
       SELECT text_concatenar(CASE WHEN not nullvalue(iflf.nroinforme) THEN 
                              concat(''Liq. '', iflf.idliquidacion,''-'',idcentroliquidacion)
			     ELSE ccd.movconcepto END)
 
		      FROM informefacturacioncobranza as ifc  
		      JOIN ', latablapago  , ' as ccp USING(idpago, idcentropago)                      
                      JOIN  ', latabladeudapago  , ' as ccdp USING  (idpago, idcentropago) 
                      JOIN  ', latabladeuda  , ' as ccd USING(iddeuda, idcentrodeuda)
                      LEFT JOIN informefacturacionliqfarmacia as iflf ON (ccd.idcomprobante= 
                                                             iflf.nroinforme* 100 +iflf.idcentroinformefacturacion)
                      WHERE ifc.nroinforme = ', $1, ' AND ifc.idcentroinformefacturacion=', $2 )
    INTO eltexto;

return 	eltexto;
END;
$function$
