CREATE OR REPLACE FUNCTION public.insertarccctactepagocliente(fila ctactepagocliente)
 RETURNS ctactepagocliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactepagoclientecc:= current_timestamp;
    UPDATE sincro.ctactepagocliente SET ctactepagoclientecc= fila.ctactepagoclientecc, fechamovimiento= fila.fechamovimiento, idcentroclientectacte= fila.idcentroclientectacte, idcentropago= fila.idcentropago, idclientectacte= fila.idclientectacte, idcomprobante= fila.idcomprobante, idcomprobantetipos= fila.idcomprobantetipos, idpago= fila.idpago, importe= fila.importe, movconcepto= fila.movconcepto, nrocuentac= fila.nrocuentac, saldo= fila.saldo WHERE idpago= fila.idpago AND idcentropago= fila.idcentropago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ctactepagocliente(ctactepagoclientecc, fechamovimiento, idcentroclientectacte, idcentropago, idclientectacte, idcomprobante, idcomprobantetipos, idpago, importe, movconcepto, nrocuentac, saldo) VALUES (fila.ctactepagoclientecc, fila.fechamovimiento, fila.idcentroclientectacte, fila.idcentropago, fila.idclientectacte, fila.idcomprobante, fila.idcomprobantetipos, fila.idpago, fila.importe, fila.movconcepto, fila.nrocuentac, fila.saldo);
    END IF;
    RETURN fila;
    END;
    $function$
