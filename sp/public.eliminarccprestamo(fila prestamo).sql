CREATE OR REPLACE FUNCTION public.eliminarccprestamo(fila prestamo)
 RETURNS prestamo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestamocc:= current_timestamp;
    delete from sincro.prestamo WHERE idcentroprestamo= fila.idcentroprestamo AND idprestamo= fila.idprestamo AND TRUE;
    RETURN fila;
    END;
    $function$
