CREATE OR REPLACE FUNCTION public.insertarcccomprobante(fila comprobante)
 RETURNS comprobante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.comprobantecc:= current_timestamp;
    UPDATE sincro.comprobante SET comprobantecc= fila.comprobantecc, fechahora= fila.fechahora, idcentroregional= fila.idcentroregional, idcomprobante= fila.idcomprobante WHERE idcentroregional= fila.idcentroregional AND idcomprobante= fila.idcomprobante AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.comprobante(comprobantecc, fechahora, idcentroregional, idcomprobante) VALUES (fila.comprobantecc, fila.fechahora, fila.idcentroregional, fila.idcomprobante);
    END IF;
    RETURN fila;
    END;
    $function$
