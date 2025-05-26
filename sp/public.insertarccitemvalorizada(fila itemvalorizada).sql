CREATE OR REPLACE FUNCTION public.insertarccitemvalorizada(fila itemvalorizada)
 RETURNS itemvalorizada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.itemvalorizadacc:= current_timestamp;
    UPDATE sincro.itemvalorizada SET auditada= fila.auditada, centro= fila.centro, iditem= fila.iditem, idplancovertura= fila.idplancovertura, itemvalorizadacc= fila.itemvalorizadacc, nroorden= fila.nroorden WHERE centro= fila.centro AND iditem= fila.iditem AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.itemvalorizada(auditada, centro, iditem, idplancovertura, itemvalorizadacc, nroorden) VALUES (fila.auditada, fila.centro, fila.iditem, fila.idplancovertura, fila.itemvalorizadacc, fila.nroorden);
    END IF;
    RETURN fila;
    END;
    $function$
