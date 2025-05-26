CREATE OR REPLACE FUNCTION public.insertarccordenpagocontableordenpago(fila ordenpagocontableordenpago)
 RETURNS ordenpagocontableordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocontableordenpagocc:= current_timestamp;
    UPDATE sincro.ordenpagocontableordenpago SET idcentroordenpago= fila.idcentroordenpago, idcentroordenpagocontable= fila.idcentroordenpagocontable, idordenpagocontable= fila.idordenpagocontable, nroordenpago= fila.nroordenpago, ordenpagocontableordenpagocc= fila.ordenpagocontableordenpagocc WHERE idordenpagocontable= fila.idordenpagocontable AND idcentroordenpago= fila.idcentroordenpago AND idcentroordenpagocontable= fila.idcentroordenpagocontable AND nroordenpago= fila.nroordenpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenpagocontableordenpago(idcentroordenpago, idcentroordenpagocontable, idordenpagocontable, nroordenpago, ordenpagocontableordenpagocc) VALUES (fila.idcentroordenpago, fila.idcentroordenpagocontable, fila.idordenpagocontable, fila.nroordenpago, fila.ordenpagocontableordenpagocc);
    END IF;
    RETURN fila;
    END;
    $function$
