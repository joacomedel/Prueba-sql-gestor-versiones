CREATE OR REPLACE FUNCTION public.insertarccordinternacion(fila ordinternacion)
 RETURNS ordinternacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordinternacioncc:= current_timestamp;
    UPDATE sincro.ordinternacion SET cantdias= fila.cantdias, centro= fila.centro, diagnostico= fila.diagnostico, fechainternacion= fila.fechainternacion, idplancovertura= fila.idplancovertura, idprestador= fila.idprestador, lugarinternacion= fila.lugarinternacion, malcance= fila.malcance, mespecialidad= fila.mespecialidad, nromatricula= fila.nromatricula, nroorden= fila.nroorden, ordinternacioncc= fila.ordinternacioncc, tipointernacion= fila.tipointernacion WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordinternacion(cantdias, centro, diagnostico, fechainternacion, idplancovertura, idprestador, lugarinternacion, malcance, mespecialidad, nromatricula, nroorden, ordinternacioncc, tipointernacion) VALUES (fila.cantdias, fila.centro, fila.diagnostico, fila.fechainternacion, fila.idplancovertura, fila.idprestador, fila.lugarinternacion, fila.malcance, fila.mespecialidad, fila.nromatricula, fila.nroorden, fila.ordinternacioncc, fila.tipointernacion);
    END IF;
    RETURN fila;
    END;
    $function$
