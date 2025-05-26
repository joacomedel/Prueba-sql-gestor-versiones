CREATE OR REPLACE FUNCTION public.insertarccorden(fila orden)
 RETURNS orden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordencc:= current_timestamp;
    UPDATE sincro.orden SET asi= fila.asi, centro= fila.centro, centroordeninter= fila.centroordeninter, fechaemision= fila.fechaemision, idasocconv= fila.idasocconv, nroorden= fila.nroorden, nroordeninter= fila.nroordeninter, ordencc= fila.ordencc, tipo= fila.tipo WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.orden(asi, centro, centroordeninter, fechaemision, idasocconv, nroorden, nroordeninter, ordencc, tipo) VALUES (fila.asi, fila.centro, fila.centroordeninter, fila.fechaemision, fila.idasocconv, fila.nroorden, fila.nroordeninter, fila.ordencc, fila.tipo);
    END IF;
    RETURN fila;
    END;
    $function$
