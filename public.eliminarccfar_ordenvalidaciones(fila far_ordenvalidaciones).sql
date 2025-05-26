CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenvalidaciones(fila far_ordenvalidaciones)
 RETURNS far_ordenvalidaciones
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenvalidacionescc:= current_timestamp;
    delete from sincro.far_ordenvalidaciones WHERE idordenventa= fila.idordenventa AND idcentroordenventa= fila.idcentroordenventa AND idvalidacion= fila.idvalidacion AND idcentrovalidacion= fila.idcentrovalidacion AND TRUE;
    RETURN fila;
    END;
    $function$
