CREATE OR REPLACE FUNCTION public.eliminarccrecibocupon(fila recibocupon)
 RETURNS recibocupon
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibocuponcc:= current_timestamp;
    delete from sincro.recibocupon WHERE idcentrorecibocupon= fila.idcentrorecibocupon AND idrecibocupon= fila.idrecibocupon AND TRUE;
    RETURN fila;
    END;
    $function$
