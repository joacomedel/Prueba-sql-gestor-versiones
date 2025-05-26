CREATE OR REPLACE FUNCTION public.eliminarccrecepcion(fila recepcion)
 RETURNS recepcion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recepcioncc:= current_timestamp;
    delete from sincro.recepcion WHERE idcentroregional= fila.idcentroregional AND idrecepcion= fila.idrecepcion AND TRUE;
    RETURN fila;
    END;
    $function$
