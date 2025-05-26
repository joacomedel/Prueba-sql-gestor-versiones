CREATE OR REPLACE FUNCTION public.eliminarccfar_validacion(fila far_validacion)
 RETURNS far_validacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacioncc:= current_timestamp;
    delete from sincro.far_validacion WHERE idvalidacion= fila.idvalidacion AND idcentrovalidacion= fila.idcentrovalidacion AND TRUE;
    RETURN fila;
    END;
    $function$
