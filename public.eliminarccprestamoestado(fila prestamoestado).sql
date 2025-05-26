CREATE OR REPLACE FUNCTION public.eliminarccprestamoestado(fila prestamoestado)
 RETURNS prestamoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestamoestadocc:= current_timestamp;
    delete from sincro.prestamoestado WHERE idcentroprestamoestado= fila.idcentroprestamoestado AND idprestamoestado= fila.idprestamoestado AND TRUE;
    RETURN fila;
    END;
    $function$
