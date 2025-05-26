CREATE OR REPLACE FUNCTION public.eliminarccacciofar(fila acciofar)
 RETURNS acciofar
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.acciofarcc:= current_timestamp;
    delete from sincro.acciofar WHERE idacciofar= fila.idacciofar AND TRUE;
    RETURN fila;
    END;
    $function$
