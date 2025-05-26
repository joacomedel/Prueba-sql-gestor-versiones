CREATE OR REPLACE FUNCTION public.eliminarcccuentacorrientedeudapagoordenpago(fila cuentacorrientedeudapagoordenpago)
 RETURNS cuentacorrientedeudapagoordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeudapagoordenpagocc:= current_timestamp;
    delete from sincro.cuentacorrientedeudapagoordenpago WHERE idpago= fila.idpago AND iddeuda= fila.iddeuda AND idcentrodeuda= fila.idcentrodeuda AND idcentropago= fila.idcentropago AND nroordenpago= fila.nroordenpago AND idcentroordenpago= fila.idcentroordenpago AND TRUE;
    RETURN fila;
    END;
    $function$
