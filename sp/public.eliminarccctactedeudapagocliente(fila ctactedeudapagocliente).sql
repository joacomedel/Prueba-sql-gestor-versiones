CREATE OR REPLACE FUNCTION public.eliminarccctactedeudapagocliente(fila ctactedeudapagocliente)
 RETURNS ctactedeudapagocliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactedeudapagoclientecc:= current_timestamp;
    delete from sincro.ctactedeudapagocliente WHERE idctactedeudapagocliente= fila.idctactedeudapagocliente AND idcentroctactedeudapagocliente= fila.idcentroctactedeudapagocliente AND TRUE;
    RETURN fila;
    END;
    $function$
