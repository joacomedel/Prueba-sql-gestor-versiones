CREATE OR REPLACE FUNCTION public.insertarccordenrecibo(fila ordenrecibo)
 RETURNS ordenrecibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenrecibocc:= current_timestamp;
    UPDATE sincro.ordenrecibo SET centro= fila.centro, idrecibo= fila.idrecibo, nroorden= fila.nroorden, ordenrecibocc= fila.ordenrecibocc WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenrecibo(centro, idrecibo, nroorden, ordenrecibocc) VALUES (fila.centro, fila.idrecibo, fila.nroorden, fila.ordenrecibocc);
    END IF;
    RETURN fila;
    END;
    $function$
