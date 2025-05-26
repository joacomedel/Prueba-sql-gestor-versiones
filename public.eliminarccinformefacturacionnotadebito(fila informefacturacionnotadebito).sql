CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacionnotadebito(fila informefacturacionnotadebito)
 RETURNS informefacturacionnotadebito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionnotadebitocc:= current_timestamp;
    delete from sincro.informefacturacionnotadebito WHERE idcentrodebitofacturaprestador= fila.idcentrodebitofacturaprestador AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND iddebitofacturaprestador= fila.iddebitofacturaprestador AND nroinforme= fila.nroinforme AND TRUE;
    RETURN fila;
    END;
    $function$
