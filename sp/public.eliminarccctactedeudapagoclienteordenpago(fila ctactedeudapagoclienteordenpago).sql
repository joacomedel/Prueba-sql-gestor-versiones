CREATE OR REPLACE FUNCTION public.eliminarccctactedeudapagoclienteordenpago(fila ctactedeudapagoclienteordenpago)
 RETURNS ctactedeudapagoclienteordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctactedeudapagoclienteordenpagocc:= current_timestamp;
    delete from sincro.ctactedeudapagoclienteordenpago WHERE idctactedeudapagocliente= fila.idctactedeudapagocliente AND idcentroctactedeudapagocliente= fila.idcentroctactedeudapagocliente AND nroordenpago= fila.nroordenpago AND idcentroordenpago= fila.idcentroordenpago AND TRUE;
    RETURN fila;
    END;
    $function$
