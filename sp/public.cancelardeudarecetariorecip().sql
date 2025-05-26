CREATE OR REPLACE FUNCTION public.cancelardeudarecetariorecip()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    cursorconsumo refcursor;
   recdeuda RECORD;
    resultado BOOLEAN;
    unconsumo RECORD;
    comprobantemovimiento BIGINT;
        movimientoconcepto VARCHAR;
        nrocuentacontable VARCHAR;
      
	
BEGIN
  OPEN cursorconsumo FOR SELECT * FROM informefacturacionreciprocidad NATURAL JOIN orden 
WHERE idcomprobantetipos=13;
 
  FETCH cursorconsumo into unconsumo;
 WHILE found LOOP

   movimientoconcepto =concat( 'Cancelación de deuda de orden ' , to_char(unconsumo.nroorden,'00000000') , '-' , to_char(unconsumo.centro,'000') , ' por creacion de informe nro ' ,  unconsumo.nroinforme );
 comprobantemovimiento = unconsumo.nroorden * 100 + unconsumo.centro;

--Busco la deuda de la orden

 SELECT INTO recdeuda * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.idcomprobantetipos = 14
				AND cuentacorrientedeuda.idcomprobante = comprobantemovimiento;
   IF FOUND THEN 

   INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
VALUES (21,recdeuda.tipodoc,recdeuda.idctacte,CURRENT_TIMESTAMP,movimientoconcepto,'50350',recdeuda.importe * (- 1::double precision),comprobantemovimiento,0,999,recdeuda.idctacte);
			                
INSERT INTO cuentacorrientedeudapago(iddeuda,idcentrodeuda,idpago,idcentropago,fechamovimientoimputacion,importeimp)
VALUES (recdeuda.iddeuda,recdeuda.idcentrodeuda,currval('cuentacorrientepagos_idpago_seq'),centro(),CURRENT_TIMESTAMP,recdeuda.saldo);

UPDATE cuentacorrientedeuda SET saldo = 0 WHERE cuentacorrientedeuda.iddeuda = recdeuda.iddeuda
AND cuentacorrientedeuda.idcentrodeuda = recdeuda.idcentrodeuda;

  END IF;
  FETCH cursorconsumo into unconsumo;
  END LOOP;

close cursorconsumo;	

UPDATE informefacturacionreciprocidad set idcomprobantetipos=14 
WHERE idcomprobantetipos=13;

return resultado;
END;
$function$
