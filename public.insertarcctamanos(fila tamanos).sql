CREATE OR REPLACE FUNCTION public.insertarcctamanos(fila tamanos)
 RETURNS tamanos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tamanoscc:= current_timestamp;
    UPDATE sincro.tamanos SET idtamanos= fila.idtamanos, tamanoscc= fila.tamanoscc, tdescripcion= fila.tdescripcion WHERE idtamanos= fila.idtamanos AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.tamanos(idtamanos, tamanoscc, tdescripcion) VALUES (fila.idtamanos, fila.tamanoscc, fila.tdescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
