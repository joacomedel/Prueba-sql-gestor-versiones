CREATE OR REPLACE FUNCTION public.eliminarccctactedeudacliente(fila ctactedeudacliente)
 RETURNS ctactedeudacliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactedeudaclientecc:= current_timestamp;
    delete from sincro.ctactedeudacliente WHERE iddeuda= fila.iddeuda AND idcentrodeuda= fila.idcentrodeuda AND TRUE;
    RETURN fila;
    END;
    $function$
