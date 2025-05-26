CREATE OR REPLACE FUNCTION public.insertarccreciboautomatico(fila reciboautomatico)
 RETURNS reciboautomatico
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reciboautomaticocc:= current_timestamp;
    UPDATE sincro.reciboautomatico SET centro= fila.centro, idorigenrecibo= fila.idorigenrecibo, idrecibo= fila.idrecibo, reciboautomaticocc= fila.reciboautomaticocc WHERE centro= fila.centro AND idrecibo= fila.idrecibo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.reciboautomatico(centro, idorigenrecibo, idrecibo, reciboautomaticocc) VALUES (fila.centro, fila.idorigenrecibo, fila.idrecibo, fila.reciboautomaticocc);
    END IF;
    RETURN fila;
    END;
    $function$
