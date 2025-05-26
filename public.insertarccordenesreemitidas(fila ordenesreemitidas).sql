CREATE OR REPLACE FUNCTION public.insertarccordenesreemitidas(fila ordenesreemitidas)
 RETURNS ordenesreemitidas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenesreemitidascc:= current_timestamp;
    UPDATE sincro.ordenesreemitidas SET centro= fila.centro, nroorden= fila.nroorden, ordenesreemitidascc= fila.ordenesreemitidascc, ordenreemitida= fila.ordenreemitida WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenesreemitidas(centro, nroorden, ordenesreemitidascc, ordenreemitida) VALUES (fila.centro, fila.nroorden, fila.ordenesreemitidascc, fila.ordenreemitida);
    END IF;
    RETURN fila;
    END;
    $function$
