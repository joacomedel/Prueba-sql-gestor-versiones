CREATE OR REPLACE FUNCTION public.eliminarccrecibocuponlote(fila recibocuponlote)
 RETURNS recibocuponlote
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibocuponlotecc:= current_timestamp;
    delete from sincro.recibocuponlote WHERE idrecibocupon= fila.idrecibocupon AND idcentrorecibocupon= fila.idcentrorecibocupon AND TRUE;
    RETURN fila;
    END;
    $function$
