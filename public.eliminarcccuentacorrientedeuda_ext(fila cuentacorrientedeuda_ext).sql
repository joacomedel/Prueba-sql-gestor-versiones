CREATE OR REPLACE FUNCTION public.eliminarcccuentacorrientedeuda_ext(fila cuentacorrientedeuda_ext)
 RETURNS cuentacorrientedeuda_ext
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeuda_extcc:= current_timestamp;
    delete from sincro.cuentacorrientedeuda_ext WHERE iddeuda= fila.iddeuda AND idcentrodeuda= fila.idcentrodeuda AND TRUE;
    RETURN fila;
    END;
    $function$
