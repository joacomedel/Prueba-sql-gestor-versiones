CREATE OR REPLACE FUNCTION public.ctactenoafilimputar(bigint, integer, bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

	regpago  RECORD;
	regdeuda RECORD;
	importepago double precision ;

    nuevosaldodeuda double precision ;
    nuevosaldopago double precision ;
    importeimput double precision ;
    difdeudapago double precision ;


	eliddeuda bigint;
	elidcentrodeuda  integer;
	elidpago bigint;
	elidcentropago integer;
  	respuesta boolean;
	
	
BEGIN
     -- $1 $2 iddeuda,idcentrodeuda
     -- $3 $4 idpago,idcentropago
     eliddeuda = $1;      elidcentrodeuda =$2;
     elidpago =$3;        elidcentropago =$4;

     respuesta = FALSE;

     SELECT INTO regpago * FROM ctactepagonoafil WHERE idcentropago = elidcentropago and idpago =elidpago;

     SELECT INTO regdeuda * FROM ctactedeudanoafil WHERE iddeuda = eliddeuda and idcentrodeuda =elidcentrodeuda;

      -- Guardo el importe del pago
      importepago = regpago.saldo;


      -- diferencia entre la deuda y el pago
      difdeudapago = regdeuda.saldo -  abs(importepago);
      
      
      IF (importepago <>0) THEN
                     
                     if(difdeudapago < 0 ) THEN  -- El importe del pago es mayor al importe de la deuda
                            nuevosaldodeuda = 0;
                            nuevosaldopago = -1 * abs(difdeudapago);
                            importeimput = regdeuda.saldo;
                     ELSE   -- El importe del pago es menor al importe de la deuda
                            nuevosaldodeuda = difdeudapago;
                            nuevosaldopago = 0;
                            importeimput = abs(importepago);
                     END IF;
                     
                     -- Actualizo el saldo de la deuda
                     UPDATE ctactedeudanoafil SET saldo = nuevosaldodeuda
                     WHERE iddeuda=eliddeuda and idcentrodeuda =elidcentrodeuda;

                     -- vincula la deuda con el pago
                     INSERT INTO ctactedeudapagonoafil(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp)
                     VALUES(elidpago,eliddeuda,elidcentrodeuda,elidcentropago,importeimput);

                     -- actualizo el saldo del pago
                     UPDATE ctactepagonoafil SET saldo =nuevosaldopago
                     WHERE idpago=elidpago and idcentropago =elidcentropago;

                     respuesta =true;
       END IF;
    
RETURN respuesta;
END;
$function$
