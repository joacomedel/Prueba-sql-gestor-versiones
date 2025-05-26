CREATE OR REPLACE FUNCTION public.insertarccpagoordenpagocontable(fila pagoordenpagocontable)
 RETURNS pagoordenpagocontable
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pagoordenpagocontablecc:= current_timestamp;
    UPDATE sincro.pagoordenpagocontable SET idcentrocheque= fila.idcentrocheque, idcentroordenpagocontable= fila.idcentroordenpagocontable, idcentropagoordenpagocontable= fila.idcentropagoordenpagocontable, idcheque= fila.idcheque, idordenpagocontable= fila.idordenpagocontable, idpagoordenpagocontable= fila.idpagoordenpagocontable, idvalorescaja= fila.idvalorescaja, pagoordenpagocontablecc= fila.pagoordenpagocontablecc, popmonto= fila.popmonto, popobservacion= fila.popobservacion WHERE idcentropagoordenpagocontable= fila.idcentropagoordenpagocontable AND idpagoordenpagocontable= fila.idpagoordenpagocontable AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.pagoordenpagocontable(idcentrocheque, idcentroordenpagocontable, idcentropagoordenpagocontable, idcheque, idordenpagocontable, idpagoordenpagocontable, idvalorescaja, pagoordenpagocontablecc, popmonto, popobservacion) VALUES (fila.idcentrocheque, fila.idcentroordenpagocontable, fila.idcentropagoordenpagocontable, fila.idcheque, fila.idordenpagocontable, fila.idpagoordenpagocontable, fila.idvalorescaja, fila.pagoordenpagocontablecc, fila.popmonto, fila.popobservacion);
    END IF;
    RETURN fila;
    END;
    $function$
