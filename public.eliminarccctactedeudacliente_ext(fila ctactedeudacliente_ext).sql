CREATE OR REPLACE FUNCTION public.eliminarccctactedeudacliente_ext(fila ctactedeudacliente_ext)
 RETURNS ctactedeudacliente_ext
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactedeudacliente_extcc:= current_timestamp;
    delete from sincro.ctactedeudacliente_ext WHERE iddeuda= fila.iddeuda AND idcentrodeuda= fila.idcentrodeuda AND TRUE;
    RETURN fila;
    END;
    $function$
