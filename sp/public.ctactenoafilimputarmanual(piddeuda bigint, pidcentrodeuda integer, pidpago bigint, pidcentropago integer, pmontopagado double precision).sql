CREATE OR REPLACE FUNCTION public.ctactenoafilimputarmanual(piddeuda bigint, pidcentrodeuda integer, pidpago bigint, pidcentropago integer, pmontopagado double precision)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	regpago  RECORD;
	regdeuda RECORD;
    nuevosaldodeuda double precision ;
    nuevosaldopago double precision ;
    importeimput double precision ;
    difdeudapago double precision ;
	eliddeuda bigint;
	elidcentrodeuda  integer;
	elidpago bigint;
	elidcentropago integer;
	elmontopagado double precision;
  	respuesta boolean;
	
	
BEGIN
     -- $1 $2 iddeuda,idcentrodeuda
     -- $3 $4 idpago,idcentropago
     eliddeuda = $1;      elidcentrodeuda =$2;
     elidpago =$3;        elidcentropago =$4;
     elmontopagado= $5;
     

     respuesta = FALSE;

     SELECT INTO regpago * FROM ctactepagonoafil WHERE idcentropago = elidcentropago and idpago =elidpago;

     SELECT INTO regdeuda * FROM ctactedeudanoafil WHERE iddeuda = eliddeuda and idcentrodeuda =elidcentrodeuda;

     nuevosaldopago = regpago.saldo + abs(elmontopagado);
     nuevosaldodeuda = regdeuda.saldo + abs(elmontopagado);
     
     
                          -- Actualizo el saldo de la deuda
                     UPDATE ctactedeudanoafil SET saldo = nuevosaldodeuda
                     WHERE iddeuda=eliddeuda and idcentrodeuda =elidcentrodeuda;

                     -- vincula la deuda con el pago
                     INSERT INTO ctactedeudapagonoafil(idpago,iddeuda,idcentrodeuda,idcentropago,importeimp)
                     VALUES(elidpago,eliddeuda,elidcentrodeuda,elidcentropago,elmontopagado);

                     -- actualizo el saldo del pago
                     UPDATE ctactepagonoafil SET saldo =nuevosaldopago
                     WHERE idpago=elidpago and idcentropago =elidcentropago;
                     
                     respuesta =true;
     


RETURN respuesta;
END;
$function$
