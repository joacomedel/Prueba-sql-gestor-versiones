CREATE OR REPLACE FUNCTION public.eliminarcccuentacorrientedeudapago(fila cuentacorrientedeudapago)
 RETURNS cuentacorrientedeudapago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeudapagocc:= current_timestamp;
    delete from sincro.cuentacorrientedeudapago WHERE idcentrodeuda= fila.idcentrodeuda AND iddeuda= fila.iddeuda AND idpago= fila.idpago AND TRUE;
    RETURN fila;
    END;
    $function$
