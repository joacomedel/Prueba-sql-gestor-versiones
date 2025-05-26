CREATE OR REPLACE FUNCTION public.eliminarccasientoimputacion(fila asientoimputacion)
 RETURNS asientoimputacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientoimputacioncc:= current_timestamp;
    delete from sincro.asientoimputacion WHERE idasientocontable= fila.idasientocontable AND idasientoimputacion= fila.idasientoimputacion AND idcentroregional= fila.idcentroregional AND TRUE;
    RETURN fila;
    END;
    $function$
