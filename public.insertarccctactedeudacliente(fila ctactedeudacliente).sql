CREATE OR REPLACE FUNCTION public.insertarccctactedeudacliente(fila ctactedeudacliente)
 RETURNS ctactedeudacliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactedeudaclientecc:= current_timestamp;
    UPDATE sincro.ctactedeudacliente SET idclientectacte= fila.idclientectacte, nrocuentac= fila.nrocuentac, movconcepto= fila.movconcepto, idcentrodeuda= fila.idcentrodeuda, fechamovimiento= fila.fechamovimiento, importe= fila.importe, idcomprobante= fila.idcomprobante, idcentroclientectacte= fila.idcentroclientectacte, ccdcfechaenvio= fila.ccdcfechaenvio, iddeuda= fila.iddeuda, ctactedeudaclientecc= fila.ctactedeudaclientecc, idcomprobantetipos= fila.idcomprobantetipos, saldo= fila.saldo, fechavencimiento= fila.fechavencimiento WHERE iddeuda= fila.iddeuda AND idcentrodeuda= fila.idcentrodeuda AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ctactedeudacliente(idclientectacte, nrocuentac, movconcepto, idcentrodeuda, fechamovimiento, importe, idcomprobante, idcentroclientectacte, ccdcfechaenvio, iddeuda, ctactedeudaclientecc, idcomprobantetipos, saldo, fechavencimiento) VALUES (fila.idclientectacte, fila.nrocuentac, fila.movconcepto, fila.idcentrodeuda, fila.fechamovimiento, fila.importe, fila.idcomprobante, fila.idcentroclientectacte, fila.ccdcfechaenvio, fila.iddeuda, fila.ctactedeudaclientecc, fila.idcomprobantetipos, fila.saldo, fila.fechavencimiento);
    END IF;
    RETURN fila;
    END;
    $function$
