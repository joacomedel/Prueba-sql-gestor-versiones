CREATE OR REPLACE FUNCTION public.eliminarccpagos(fila pagos)
 RETURNS pagos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pagoscc:= current_timestamp;
    delete from sincro.pagos WHERE centro= fila.centro AND idpagos= fila.idpagos AND TRUE;
    RETURN fila;
    END;
    $function$
