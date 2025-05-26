CREATE OR REPLACE FUNCTION public.eliminarcccuentacorrientedeuda(fila cuentacorrientedeuda)
 RETURNS cuentacorrientedeuda
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeudacc:= current_timestamp;
    delete from sincro.cuentacorrientedeuda WHERE idcentrodeuda= fila.idcentrodeuda AND iddeuda= fila.iddeuda AND TRUE;
    RETURN fila;
    END;
    $function$
