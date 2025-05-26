CREATE OR REPLACE FUNCTION public.insertarccrecibousuario(fila recibousuario)
 RETURNS recibousuario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibousuariocc:= current_timestamp;
    UPDATE sincro.recibousuario SET centro= fila.centro, idrecibo= fila.idrecibo, idusuario= fila.idusuario, recibousuariocc= fila.recibousuariocc WHERE centro= fila.centro AND idrecibo= fila.idrecibo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recibousuario(centro, idrecibo, idusuario, recibousuariocc) VALUES (fila.centro, fila.idrecibo, fila.idusuario, fila.recibousuariocc);
    END IF;
    RETURN fila;
    END;
    $function$
