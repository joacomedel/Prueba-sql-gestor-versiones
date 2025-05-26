CREATE OR REPLACE FUNCTION public.configurarctactevinculadainformecliente(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado

 --Registros 
   rladeuda RECORD;
   rimputada RECORD;

BEGIN



	SELECT INTO rladeuda * FROM ctactedeudacliente WHERE ctactedeudacliente.idcomprobante =$1 * 100 + $2
                                   AND ctactedeudacliente.idcomprobantetipos = 21;

	IF FOUND THEN 
		 UPDATE ctactedeudacliente SET saldo =  0, importe =  0,
		 movconcepto = CONCAT('Deuda cancelada al anularse el comprobante de facturacion asociado. ', movconcepto)
		WHERE iddeuda = rladeuda.iddeuda AND idcentrodeuda = rladeuda.idcentrodeuda;

		SELECT INTO rimputada * FROM ctactedeudapagocliente 
			WHERE iddeuda = rladeuda.iddeuda AND idcentrodeuda = rladeuda.idcentrodeuda;
		IF FOUND THEN 
			UPDATE  ctactedeudapagocliente SET importeimp = 0 WHERE iddeuda = rladeuda.iddeuda AND idcentrodeuda = rladeuda.idcentrodeuda;
                        
                        UPDATE ctactepagocliente SET saldo = importe + T.importeimp, 
		            movconcepto = CONCAT('Pago cancelado al desemputarse la deuda  por anulación del comprobante de facturacion asociado a la deuda. ', movconcepto)
	                    FROM (SELECT SUM(importeimp) AS importeimp,idpago, idcentropago 
                                    FROM ctactedeudapagocliente 
		                    WHERE idpago = rimputada.idpago AND idcentropago = rimputada.idcentropago
                                    GROUP BY idpago, idcentropago) AS T

	                        WHERE ctactepagocliente.idpago = T.idpago AND ctactepagocliente.idcentropago = T.idcentropago; 

 
                        UPDATE ctactepagocliente SET saldo = importe, 
		 movconcepto = CONCAT('Pago cancelado al desemputarse la deuda  por anulación del comprobante de facturacion asociado a la deuda. ', movconcepto)
		WHERE idpago = rimputada.idpago AND idcentropago = rimputada.idcentropago;
			
		END IF;

        ELSE 

--KR 16-09-19 Me fijo si corresponde a la deuda de un afiliado 
             SELECT INTO rladeuda * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.idcomprobante =$1 * 100 + $2
                                   AND cuentacorrientedeuda.idcomprobantetipos = 21;
             IF FOUND THEN 
		 UPDATE cuentacorrientedeuda SET saldo =  0, importe =  0,
		 movconcepto = CONCAT('Deuda cancelada al anularse el comprobante de facturacion asociado. ', movconcepto)
		WHERE iddeuda = rladeuda.iddeuda AND idcentrodeuda = rladeuda.idcentrodeuda;

		SELECT INTO rimputada * FROM cuentacorrientedeudapago 
			WHERE iddeuda = rladeuda.iddeuda AND idcentrodeuda = rladeuda.idcentrodeuda;
		IF FOUND THEN 
			UPDATE  cuentacorrientedeudapago SET importeimp = 0 WHERE iddeuda = rladeuda.iddeuda AND idcentrodeuda = rladeuda.idcentrodeuda;
                        
                        UPDATE cuentacorrientepagos SET saldo = importe + T.importeimp, 
		            movconcepto = CONCAT('Pago cancelado al desemputarse la deuda  por anulación del comprobante de facturacion asociado a la deuda. ', movconcepto)
	                    FROM (SELECT SUM(importeimp) AS importeimp,idpago, idcentropago 
                                    FROM cuentacorrientedeudapago 
		                    WHERE idpago = rimputada.idpago AND idcentropago = rimputada.idcentropago
                                    GROUP BY idpago, idcentropago) AS T

	                        WHERE idpago = T.idpago AND idcentropago = T.idcentropago; 

 
                        UPDATE cuentacorrientepagos SET saldo = importe, 
		 movconcepto = CONCAT('Pago cancelado al desemputarse la deuda  por anulación del comprobante de facturacion asociado a la deuda. ', movconcepto)
		WHERE idpago = rimputada.idpago AND idcentropago = rimputada.idcentropago;
			
		END IF;

            END IF;
	END IF;
 

    

	
	
return true;
END;
$function$
