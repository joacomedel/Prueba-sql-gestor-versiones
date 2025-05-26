CREATE OR REPLACE FUNCTION public.insertarccrecibocupon(fila recibocupon)
 RETURNS recibocupon
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibocuponcc:= current_timestamp;
    UPDATE sincro.recibocupon SET autorizacion= fila.autorizacion, centro= fila.centro, cuotas= fila.cuotas, idcentrorecibocupon= fila.idcentrorecibocupon, idrecibo= fila.idrecibo, idrecibocupon= fila.idrecibocupon, idvalorescaja= fila.idvalorescaja, monto= fila.monto, nrocupon= fila.nrocupon, nrotarjeta= fila.nrotarjeta, recibocuponcc= fila.recibocuponcc WHERE idcentrorecibocupon= fila.idcentrorecibocupon AND idrecibocupon= fila.idrecibocupon AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recibocupon(autorizacion, centro, cuotas, idcentrorecibocupon, idrecibo, idrecibocupon, idvalorescaja, monto, nrocupon, nrotarjeta, recibocuponcc) VALUES (fila.autorizacion, fila.centro, fila.cuotas, fila.idcentrorecibocupon, fila.idrecibo, fila.idrecibocupon, fila.idvalorescaja, fila.monto, fila.nrocupon, fila.nrotarjeta, fila.recibocuponcc);
    END IF;
    RETURN fila;
    END;
    $function$
