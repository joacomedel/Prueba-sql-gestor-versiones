CREATE OR REPLACE FUNCTION public.insertarcccuentacorrientedeudapagoordenpago(fila cuentacorrientedeudapagoordenpago)
 RETURNS cuentacorrientedeudapagoordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeudapagoordenpagocc:= current_timestamp;
    UPDATE sincro.cuentacorrientedeudapagoordenpago SET cuentacorrientedeudapagoordenpagocc= fila.cuentacorrientedeudapagoordenpagocc, idcentrodeuda= fila.idcentrodeuda, idcentroordenpago= fila.idcentroordenpago, idcentropago= fila.idcentropago, iddeuda= fila.iddeuda, idpago= fila.idpago, nroordenpago= fila.nroordenpago WHERE idpago= fila.idpago AND iddeuda= fila.iddeuda AND idcentrodeuda= fila.idcentrodeuda AND idcentropago= fila.idcentropago AND nroordenpago= fila.nroordenpago AND idcentroordenpago= fila.idcentroordenpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuentacorrientedeudapagoordenpago(cuentacorrientedeudapagoordenpagocc, idcentrodeuda, idcentroordenpago, idcentropago, iddeuda, idpago, nroordenpago) VALUES (fila.cuentacorrientedeudapagoordenpagocc, fila.idcentrodeuda, fila.idcentroordenpago, fila.idcentropago, fila.iddeuda, fila.idpago, fila.nroordenpago);
    END IF;
    RETURN fila;
    END;
    $function$
