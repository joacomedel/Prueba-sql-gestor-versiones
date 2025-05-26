CREATE OR REPLACE FUNCTION public.tesoreria_desimputar_cuentascorrientes()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$declare
      ccursor refcursor;
      elem RECORD;
      rtipocuenta RECORD;
      vresultado bigint;
      ropreclibrofact  RECORD;
      rauxdesimp RECORD;

BEGIN
 

vresultado = 0;

SELECT INTO rtipocuenta * FROM cuentacorrientedeudapagodesimputar;
IF rtipocuenta.origenctacte = 'clientectacte' OR rtipocuenta.origenctacte = 'adherentectacte' THEN
-- BelenA 26/06/23 agregue el OR en el IF anterior, antes solo entraba para cliente y ahora si es adherente hace lo mismo que con cliente para desimputar
  OPEN ccursor FOR select *
		 from cuentacorrientedeudapagodesimputar NATURAL JOIN ctactedeudapagocliente;
  FETCH ccursor INTO elem;
  WHILE  found LOOP
-- BelenA 04/04/24 seteo primero el imputado en 0, luego recalculo las imputaciones totales tanto para la deuda como para el pago
-- y les seteo el nuevo saldo en base a eso, no sumando al saldo que tenía lo que desimpute.
    UPDATE ctactedeudapagocliente SET importeimp=0  WHERE elem.iddeuda = iddeuda AND elem.idcentrodeuda = idcentrodeuda AND  elem.idpago = idpago AND 
    elem.idcentropago = idcentropago;

        SELECT INTO rauxdesimp sum(importeimp) as totalimputado
        FROM ctactedeudapagocliente
        WHERE iddeuda = elem.iddeuda AND idcentrodeuda = elem.idcentrodeuda;

	UPDATE ctactedeudacliente SET saldo = importe - rauxdesimp.totalimputado WHERE iddeuda = elem.iddeuda AND idcentrodeuda = elem.idcentrodeuda;

        SELECT INTO rauxdesimp sum(importeimp) as totalimputado
        FROM ctactedeudapagocliente
        WHERE idpago = elem.idpago AND idcentropago =  elem.idcentropago;

	UPDATE ctactepagocliente SET saldo = -1*(abs(importe) - rauxdesimp.totalimputado) WHERE idpago = elem.idpago AND idcentropago =  elem.idcentropago; 
	

	INSERT INTO ctactedeudapagodesimputar_aud (idcentrodeuda,idcentropago,iddeuda,idpago,ccdpdusuario,ccdpdobservacion,idctactedeudapagocliente,idcentroctactedeudapagocliente)
        VALUES (elem.idcentrodeuda,elem.idcentropago,elem.iddeuda,elem.idpago,sys_dar_usuarioactual(),concat('AUD. ',elem.ccdpdobservacion, ' SP tesoreria_desimputar_cuentascorrientes'),elem.idctactedeudapagocliente,elem.idcentroctactedeudapagocliente);

   
  fetch ccursor into elem;
  END LOOP;
  CLOSE ccursor;
END IF;

IF rtipocuenta.origenctacte = 'afiliadoctacte' THEN
  OPEN ccursor FOR select *
		 from cuentacorrientedeudapagodesimputar NATURAL JOIN cuentacorrientedeudapago;
  FETCH ccursor INTO elem;
  WHILE  found LOOP
-- BelenA 04/04/24 IDEM cliente y adherente
	UPDATE cuentacorrientedeudapago SET importeimp=0  WHERE elem.iddeuda = iddeuda AND elem.idcentrodeuda = idcentrodeuda AND  elem.idpago = idpago AND 
  elem.idcentropago = idcentropago;

        SELECT INTO rauxdesimp sum(importeimp) as totalimputado
        FROM cuentacorrientedeudapago
        WHERE iddeuda = elem.iddeuda AND idcentrodeuda = elem.idcentrodeuda;

    UPDATE cuentacorrientedeuda SET saldo = importe - rauxdesimp.totalimputado WHERE iddeuda = elem.iddeuda AND idcentrodeuda = elem.idcentrodeuda;

        SELECT INTO rauxdesimp sum(importeimp) as totalimputado
        FROM cuentacorrientedeudapago
        WHERE idpago = elem.idpago AND idcentropago =  elem.idcentropago;

    UPDATE cuentacorrientepagos SET saldo = -1*(abs(importe) - rauxdesimp.totalimputado) WHERE idpago = elem.idpago AND idcentropago =  elem.idcentropago; 


        INSERT INTO ctactedeudapagodesimputar_aud (idcentrodeuda,idcentropago,iddeuda,idpago,ccdpdusuario,ccdpdobservacion)
        VALUES (elem.idcentrodeuda,elem.idcentropago,elem.iddeuda,elem.idpago,sys_dar_usuarioactual(),concat('AUD. ',elem.ccdpdobservacion, ' SP tesoreria_desimputar_cuentascorrientes'));

	
  fetch ccursor into elem;
  END LOOP;
  CLOSE ccursor;
END IF;

IF rtipocuenta.origenctacte = 'prestadorctacte' THEN
  OPEN ccursor FOR select *
		 from cuentacorrientedeudapagodesimputar NATURAL JOIN ctactedeudapagoprestador;
  FETCH ccursor INTO elem;
  WHILE  found LOOP
-- BelenA 04/04/24 IDEM cliente y adherente	
    UPDATE ctactedeudapagoprestador SET importeimp=0  WHERE elem.iddeuda = iddeuda AND elem.idcentrodeuda = idcentrodeuda AND  elem.idpago = idpago AND 
  elem.idcentropago = idcentropago;

        SELECT INTO rauxdesimp sum(importeimp) as totalimputado
        FROM ctactedeudapagoprestador
        WHERE iddeuda = elem.iddeuda AND idcentrodeuda = elem.idcentrodeuda;

    UPDATE ctactedeudaprestador SET saldo = importe - rauxdesimp.totalimputado WHERE iddeuda = elem.iddeuda AND idcentrodeuda = elem.idcentrodeuda;

        SELECT INTO rauxdesimp sum(importeimp) as totalimputado
        FROM ctactedeudapagoprestador
        WHERE idpago = elem.idpago AND idcentropago =  elem.idcentropago;

    UPDATE ctactepagoprestador SET saldo = -1*(abs(importe) - rauxdesimp.totalimputado) WHERE idpago = elem.idpago AND idcentropago =  elem.idcentropago; 


        INSERT INTO ctactedeudapagodesimputar_aud (idcentrodeuda,idcentropago,iddeuda,idpago,ccdpdusuario,ccdpdobservacion,idctactedeudapagoprestador)
        VALUES (elem.idcentrodeuda,elem.idcentropago,elem.iddeuda,elem.idpago,sys_dar_usuarioactual(),concat('AUD. ',elem.ccdpdobservacion, ' SP tesoreria_desimputar_cuentascorrientes'),elem.idctactedeudapagoprestador);

        SELECT INTO ropreclibrofact * FROM ctactepagoprestador JOIN ordenpagocontable ON idcomprobante= (idordenpagocontable*10)+idcentroordenpagocontable
           WHERE idpago = elem.idpago AND idcentropago =  elem.idcentropago; 
--SI el pago esta vinculado entre OPC Y RECLIBROFACT entonces elimino tbn de esta tabla 
        IF FOUND THEN 
           DELETE FROM ordenpagocontablereclibrofact where idordenpagocontable=ropreclibrofact.idordenpagocontable AND idcentroordenpagocontable=ropreclibrofact.idcentroordenpagocontable;
        END IF; 
	
  fetch ccursor into elem;
  END LOOP;
  CLOSE ccursor;
END IF;

return vresultado;
END;$function$
