CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventareceta(fila far_ordenventareceta)
 RETURNS far_ordenventareceta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventarecetacc:= current_timestamp;
    UPDATE sincro.far_ordenventareceta SET centro= fila.centro, far_ordenventarecetacc= fila.far_ordenventarecetacc, idcentroordenventa= fila.idcentroordenventa, idcentroordenventaprofesion= fila.idcentroordenventaprofesion, idordenventa= fila.idordenventa, idordenventaprofesional= fila.idordenventaprofesional, idprestador= fila.idprestador, malcance= fila.malcance, mespecialidad= fila.mespecialidad, nromatricula= fila.nromatricula, nrorecetario= fila.nrorecetario, ovrfechauso= fila.ovrfechauso WHERE idcentroordenventaprofesion= fila.idcentroordenventaprofesion AND idordenventaprofesional= fila.idordenventaprofesional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventareceta(centro, far_ordenventarecetacc, idcentroordenventa, idcentroordenventaprofesion, idordenventa, idordenventaprofesional, idprestador, malcance, mespecialidad, nromatricula, nrorecetario, ovrfechauso) VALUES (fila.centro, fila.far_ordenventarecetacc, fila.idcentroordenventa, fila.idcentroordenventaprofesion, fila.idordenventa, fila.idordenventaprofesional, fila.idprestador, fila.malcance, fila.mespecialidad, fila.nromatricula, fila.nrorecetario, fila.ovrfechauso);
    END IF;
    RETURN fila;
    END;
    $function$
