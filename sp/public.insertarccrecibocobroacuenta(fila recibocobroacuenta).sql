CREATE OR REPLACE FUNCTION public.insertarccrecibocobroacuenta(fila recibocobroacuenta)
 RETURNS recibocobroacuenta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibocobroacuentacc:= current_timestamp;
    UPDATE sincro.recibocobroacuenta SET centro= fila.centro, idorigenrecibo= fila.idorigenrecibo, idrecibo= fila.idrecibo, recibocobroacuentacc= fila.recibocobroacuentacc WHERE centro= fila.centro AND idrecibo= fila.idrecibo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recibocobroacuenta(centro, idorigenrecibo, idrecibo, recibocobroacuentacc) VALUES (fila.centro, fila.idorigenrecibo, fila.idrecibo, fila.recibocobroacuentacc);
    END IF;
    RETURN fila;
    END;
    $function$
