CREATE OR REPLACE FUNCTION public.insertarccrecetarioconvenio(fila recetarioconvenio)
 RETURNS recetarioconvenio
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetarioconveniocc:= current_timestamp;
    UPDATE sincro.recetarioconvenio SET centro= fila.centro, idosexterna= fila.idosexterna, nrorecetario= fila.nrorecetario, numrecetario= fila.numrecetario, recetarioconveniocc= fila.recetarioconveniocc WHERE centro= fila.centro AND nrorecetario= fila.nrorecetario AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetarioconvenio(centro, idosexterna, nrorecetario, numrecetario, recetarioconveniocc) VALUES (fila.centro, fila.idosexterna, fila.nrorecetario, fila.numrecetario, fila.recetarioconveniocc);
    END IF;
    RETURN fila;
    END;
    $function$
