CREATE OR REPLACE FUNCTION public.eliminarccfar_ubicacion(fila far_ubicacion)
 RETURNS far_ubicacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ubicacioncc:= current_timestamp;
    delete from sincro.far_ubicacion WHERE idcentroubicacion= fila.idcentroubicacion AND idubicacion= fila.idubicacion AND TRUE;
    RETURN fila;
    END;
    $function$
