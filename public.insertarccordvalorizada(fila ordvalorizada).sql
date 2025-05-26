CREATE OR REPLACE FUNCTION public.insertarccordvalorizada(fila ordvalorizada)
 RETURNS ordvalorizada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordvalorizadacc:= current_timestamp;
    UPDATE sincro.ordvalorizada SET centro= fila.centro, centroreemitida= fila.centroreemitida, malcance= fila.malcance, mespecialidad= fila.mespecialidad, nromatricula= fila.nromatricula, nroorden= fila.nroorden, ordenreemitida= fila.ordenreemitida, ordvalorizadacc= fila.ordvalorizadacc WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordvalorizada(centro, centroreemitida, malcance, mespecialidad, nromatricula, nroorden, ordenreemitida, ordvalorizadacc) VALUES (fila.centro, fila.centroreemitida, fila.malcance, fila.mespecialidad, fila.nromatricula, fila.nroorden, fila.ordenreemitida, fila.ordvalorizadacc);
    END IF;
    RETURN fila;
    END;
    $function$
