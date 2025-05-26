CREATE OR REPLACE FUNCTION public.asentarconsumorecetarioctacte(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
--	respuesta = boolean;
--    cursorre refcursor;
    unconsumo RECORD;
   datoscuentacorriente RECORD;
   titureci RECORD;
   ordenanulada RECORD;
   movimietocancelar RECORD;
   nrocomprobante alias for $1;
   lugarcomprobante alias for $2;
   nrocuentacontable VARCHAR;
   idcuentacorriente VARCHAR;
   movimientoconcepto VARCHAR;
   
   fechamov  TIMESTAMP;
   signomovimiento INTEGER;
   idtipocuentacorriente INTEGER;
   comprobantemovimiento BIGINT;
BEGIN
select into unconsumo * from
	recetario natural join consumorecetarioreciprocidad
	where nrorecetario = nrocomprobante and
	centro = lugarcomprobante;

       nrocuentacontable = '10311'; --Cta Cte Asistencial NQN
       fechamov = unconsumo.fechaemision;
       movimientoconcepto =concat('Pago Coseguro de Recetario ' , to_char(unconsumo.nrorecetario,'00000000') , '-' , to_char(unconsumo.centro,'000'));
       
       IF unconsumo.importeapagar >= 0 THEN signomovimiento = 1;
       ELSE signomovimiento = -1; END IF;
       comprobantemovimiento = unconsumo.nrorecetario * 100 + unconsumo.centro;
 
--update cuentacorriente set importe = unconsumo.importe*signomovimiento, signo = signomovimiento where idcomprobante = comprobantemovimiento and movconcepto ilike 'Pago Coseguro de Recetario %';
--MaLaPi 17-01-2008 Modificado para que utilice la nueva estructura de BBDD
IF signomovimiento = 1 THEN --Se trata de una deuda
   UPDATE cuentacorrientedeuda SET importe = unconsumo.importe
       WHERE idcomprobante = comprobantemovimiento
       AND movconcepto ILIKE 'Pago Coseguro de Recetario %';
       IF NOT FOUND THEN
              INSERT INTO  cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
              VALUES (unconsumo.tipocomprobante,unconsumo.tipocuenta,unconsumo.abreviatura,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.importe*signomovimiento,comprobantemovimiento,unconsumo.importe*signomovimiento,387,unconsumo.abreviatura);
       END IF;
ELSE --Se trata de un importe a favor
   UPDATE cuentacorrientepagos SET importe = unconsumo.importe
       WHERE idcomprobante = comprobantemovimiento
       AND movconcepto ILIKE 'Pago Coseguro de Recetario %';
       IF NOT FOUND THEN
              INSERT INTO  cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
              VALUES (unconsumo.tipocomprobante,unconsumo.tipocuenta,unconsumo.abreviatura,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.importe*signomovimiento,comprobantemovimiento,unconsumo.importe*signomovimiento,387,unconsumo.abreviatura);
       END IF;

END IF;
--respuesta = 'false';
return 'true';
END;
$function$
