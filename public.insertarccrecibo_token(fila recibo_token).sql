CREATE OR REPLACE FUNCTION public.insertarccrecibo_token(fila recibo_token)
 RETURNS recibo_token
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibo_tokencc:= current_timestamp;
    UPDATE sincro.recibo_token SET centro= fila.centro, idrecibo= fila.idrecibo, pttoken= fila.pttoken, recibo_tokencc= fila.recibo_tokencc, rtfechaingreso= fila.rtfechaingreso WHERE idrecibo= fila.idrecibo AND centro= fila.centro AND pttoken= fila.pttoken AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recibo_token(centro, idrecibo, pttoken, recibo_tokencc, rtfechaingreso) VALUES (fila.centro, fila.idrecibo, fila.pttoken, fila.recibo_tokencc, fila.rtfechaingreso);
    END IF;
    RETURN fila;
    END;
    $function$
