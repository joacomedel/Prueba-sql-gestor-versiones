CREATE OR REPLACE FUNCTION public.tesoreria_adherente_asentarimputaciondescuentoctacte(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Funcion que realiza la imputación  de pagos */
DECLARE
       curdescuento refcursor;
       undescuento RECORD;
       rdeuda RECORD;
       rpago RECORD;
       rexistedeudapago RECORD;
       relcliente RECORD;
       saldodeuda DOUBLE PRECISION; 
       saldopago DOUBLE PRECISION;
       importe_imp DOUBLE PRECISION;
       vcartelmostrar VARCHAR;
BEGIN

-- se busca las imputaciones realizadas
OPEN curdescuento FOR SELECT *
                          FROM tempimputacion
                          ORDER BY tempimputacion.idpago,iddeuda;

FETCH curdescuento INTO undescuento;
WHILE  found LOOP
       SELECT INTO rdeuda * FROM ctactedeudacliente WHERE iddeuda = undescuento.iddeuda AND idcentrodeuda = undescuento.idcentrodeuda AND saldo > 0;       
       IF FOUND THEN 
            SELECT INTO rpago * FROM ctactepagocliente WHERE idpago = undescuento.idpago AND idcentropago = undescuento.idcentropago AND saldo <> 0;
            -- BelenA 04/04/24 con Vivi modificamos la forma en la que se calcula la imputacion y luego se actualizan los saldos 
            IF FOUND THEN 
                  saldodeuda = rdeuda.saldo - abs(rpago.saldo) ;
                  importe_imp = 0;
                  IF (saldodeuda <0 ) THEN----- Pago es mayor a la deuda
                  
                       importe_imp = rdeuda.saldo;
                       saldodeuda = 0;
                       saldopago = abs(rpago.saldo) -importe_imp;

                  ELSE  --- Pago es menor o igual a la deuda
                        importe_imp = abs( rpago.saldo);
                        saldopago = 0;

                  END IF;

               	IF (saldodeuda < 0.09  ) THEN 
		             saldodeuda = 0;
		       	END IF;
		       	IF (saldopago < 0.09  ) THEN 
		            saldopago = 0;
		       	END IF;

             	IF (saldopago = 0) THEN --- no me queda saldo en el pago
             		DELETE FROM tempimputacion WHERE idpago = rpago.idpago AND idcentropago = rpago.idcentropago;
                    close curdescuento;
                    --- refrescamos la info de las imputaciones en el record
                    OPEN curdescuento FOR SELECT *
                                          FROM tempimputacion
                                          ORDER BY tempimputacion.idpago;
             	END IF;

             	--- Actualizamos el saldo de la deuda
            	UPDATE ctactedeudacliente  SET saldo = saldodeuda, ccdcfechaenvio= null
            	WHERE iddeuda = rdeuda.iddeuda AND idcentrodeuda = rdeuda.idcentrodeuda;
    			
    			--- Actualizamos el saldo del pago 
 	        	UPDATE ctactepagocliente SET saldo = (abs(saldopago)*-1)
    	    	WHERE idpago = rpago.idpago AND idcentropago = rpago.idcentropago;
     			
     			-- Registramos la imputacion entre la deuda y el pago
 				IF(importe_imp<>0) THEN
 					INSERT INTO ctactedeudapagocliente (idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp,idusuario)
					               VALUES(rpago.idpago,rpago.idcentropago,rdeuda.iddeuda,rdeuda.idcentrodeuda,CURRENT_DATE,importe_imp, sys_dar_usuarioactual());
                END IF;
 
              
			END IF;
		END IF;
		FETCH curdescuento INTO undescuento;
		END LOOP;
		close curdescuento;
RETURN ' ';
END;$function$
