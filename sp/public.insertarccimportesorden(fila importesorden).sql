CREATE OR REPLACE FUNCTION public.insertarccimportesorden(fila importesorden)
 RETURNS importesorden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.importesordencc:= current_timestamp;
    UPDATE sincro.importesorden SET centro= fila.centro, idformapagotipos= fila.idformapagotipos, importe= fila.importe, importesordencc= fila.importesordencc, nroorden= fila.nroorden WHERE centro= fila.centro AND idformapagotipos= fila.idformapagotipos AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.importesorden(centro, idformapagotipos, importe, importesordencc, nroorden) VALUES (fila.centro, fila.idformapagotipos, fila.importe, fila.importesordencc, fila.nroorden);
    END IF;
    RETURN fila;
    END;
    $function$
