CREATE OR REPLACE FUNCTION public.eliminarccrecafiliacion(fila recafiliacion)
 RETURNS recafiliacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recafiliacioncc:= current_timestamp;
    delete from sincro.recafiliacion WHERE idrecepcion= fila.idrecepcion AND TRUE;
    RETURN fila;
    END;
    $function$
