CREATE OR REPLACE FUNCTION public.insertarccordenestados(fila ordenestados)
 RETURNS ordenestados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenestadoscc:= current_timestamp;
    UPDATE sincro.ordenestados SET centro= fila.centro, fechacambio= fila.fechacambio, idordenestadotipos= fila.idordenestadotipos, nroorden= fila.nroorden, oeidusuario= fila.oeidusuario, ordenestadoscc= fila.ordenestadoscc WHERE centro= fila.centro AND nroorden= fila.nroorden AND idordenestadotipos= fila.idordenestadotipos AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenestados(centro, fechacambio, idordenestadotipos, nroorden, oeidusuario, ordenestadoscc) VALUES (fila.centro, fila.fechacambio, fila.idordenestadotipos, fila.nroorden, fila.oeidusuario, fila.ordenestadoscc);
    END IF;
    RETURN fila;
    END;
    $function$
