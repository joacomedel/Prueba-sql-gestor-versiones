CREATE OR REPLACE FUNCTION public.insertarccctactedeudapagoclienteordenpago(fila ctactedeudapagoclienteordenpago)
 RETURNS ctactedeudapagoclienteordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactedeudapagoclienteordenpagocc:= current_timestamp;
    UPDATE sincro.ctactedeudapagoclienteordenpago SET ctactedeudapagoclienteordenpagocc= fila.ctactedeudapagoclienteordenpagocc, idcentroctactedeudapagocliente= fila.idcentroctactedeudapagocliente, idcentroordenpago= fila.idcentroordenpago, idctactedeudapagocliente= fila.idctactedeudapagocliente, nroordenpago= fila.nroordenpago WHERE idctactedeudapagocliente= fila.idctactedeudapagocliente AND idcentroctactedeudapagocliente= fila.idcentroctactedeudapagocliente AND nroordenpago= fila.nroordenpago AND idcentroordenpago= fila.idcentroordenpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ctactedeudapagoclienteordenpago(ctactedeudapagoclienteordenpagocc, idcentroctactedeudapagocliente, idcentroordenpago, idctactedeudapagocliente, nroordenpago) VALUES (fila.ctactedeudapagoclienteordenpagocc, fila.idcentroctactedeudapagocliente, fila.idcentroordenpago, fila.idctactedeudapagocliente, fila.nroordenpago);
    END IF;
    RETURN fila;
    END;
    $function$
