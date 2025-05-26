CREATE OR REPLACE FUNCTION public.insertarcccuentacorrientedeuda(fila cuentacorrientedeuda)
 RETURNS cuentacorrientedeuda
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeudacc:= current_timestamp;
    UPDATE sincro.cuentacorrientedeuda SET cuentacorrientedeudacc= fila.cuentacorrientedeudacc, fechaenvio= fila.fechaenvio, fechamovimiento= fila.fechamovimiento, idcentrodeuda= fila.idcentrodeuda, idcomprobante= fila.idcomprobante, idcomprobantetipos= fila.idcomprobantetipos, idconcepto= fila.idconcepto, idctacte= fila.idctacte, iddeuda= fila.iddeuda, importe= fila.importe, movconcepto= fila.movconcepto, nrocuentac= fila.nrocuentac, nrodoc= fila.nrodoc, saldo= fila.saldo, tipodoc= fila.tipodoc WHERE idcentrodeuda= fila.idcentrodeuda AND iddeuda= fila.iddeuda AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuentacorrientedeuda(cuentacorrientedeudacc, fechaenvio, fechamovimiento, idcentrodeuda, idcomprobante, idcomprobantetipos, idconcepto, idctacte, iddeuda, importe, movconcepto, nrocuentac, nrodoc, saldo, tipodoc) VALUES (fila.cuentacorrientedeudacc, fila.fechaenvio, fila.fechamovimiento, fila.idcentrodeuda, fila.idcomprobante, fila.idcomprobantetipos, fila.idconcepto, fila.idctacte, fila.iddeuda, fila.importe, fila.movconcepto, fila.nrocuentac, fila.nrodoc, fila.saldo, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
