CREATE OR REPLACE FUNCTION public.insertarcccuentacorrientepagos(fila cuentacorrientepagos)
 RETURNS cuentacorrientepagos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientepagoscc:= current_timestamp;
    UPDATE sincro.cuentacorrientepagos SET cuentacorrientepagoscc= fila.cuentacorrientepagoscc, fechamovimiento= fila.fechamovimiento, idcentropago= fila.idcentropago, idcomprobante= fila.idcomprobante, idcomprobantetipos= fila.idcomprobantetipos, idconcepto= fila.idconcepto, idctacte= fila.idctacte, idpago= fila.idpago, importe= fila.importe, movconcepto= fila.movconcepto, nrocuentac= fila.nrocuentac, nrodoc= fila.nrodoc, saldo= fila.saldo, tipodoc= fila.tipodoc WHERE idcentropago= fila.idcentropago AND idpago= fila.idpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuentacorrientepagos(cuentacorrientepagoscc, fechamovimiento, idcentropago, idcomprobante, idcomprobantetipos, idconcepto, idctacte, idpago, importe, movconcepto, nrocuentac, nrodoc, saldo, tipodoc) VALUES (fila.cuentacorrientepagoscc, fila.fechamovimiento, fila.idcentropago, fila.idcomprobante, fila.idcomprobantetipos, fila.idconcepto, fila.idctacte, fila.idpago, fila.importe, fila.movconcepto, fila.nrocuentac, fila.nrodoc, fila.saldo, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
