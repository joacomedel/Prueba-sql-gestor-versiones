CREATE OR REPLACE FUNCTION public.insertarccimportesrecibo(fila importesrecibo)
 RETURNS importesrecibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.importesrecibocc:= current_timestamp;
    UPDATE sincro.importesrecibo SET centro= fila.centro, idformapagotipos= fila.idformapagotipos, idrecibo= fila.idrecibo, importe= fila.importe, importesrecibocc= fila.importesrecibocc WHERE centro= fila.centro AND idformapagotipos= fila.idformapagotipos AND idrecibo= fila.idrecibo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.importesrecibo(centro, idformapagotipos, idrecibo, importe, importesrecibocc) VALUES (fila.centro, fila.idformapagotipos, fila.idrecibo, fila.importe, fila.importesrecibocc);
    END IF;
    RETURN fila;
    END;
    $function$
