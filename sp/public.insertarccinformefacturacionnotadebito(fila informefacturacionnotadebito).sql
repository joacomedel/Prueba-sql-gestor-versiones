CREATE OR REPLACE FUNCTION public.insertarccinformefacturacionnotadebito(fila informefacturacionnotadebito)
 RETURNS informefacturacionnotadebito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionnotadebitocc:= current_timestamp;
    UPDATE sincro.informefacturacionnotadebito SET idcentrodebitofacturaprestador= fila.idcentrodebitofacturaprestador, idcentroinformefacturacion= fila.idcentroinformefacturacion, iddebitofacturaprestador= fila.iddebitofacturaprestador, informefacturacionnotadebitocc= fila.informefacturacionnotadebitocc, nroinforme= fila.nroinforme WHERE idcentrodebitofacturaprestador= fila.idcentrodebitofacturaprestador AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND iddebitofacturaprestador= fila.iddebitofacturaprestador AND nroinforme= fila.nroinforme AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacionnotadebito(idcentrodebitofacturaprestador, idcentroinformefacturacion, iddebitofacturaprestador, informefacturacionnotadebitocc, nroinforme) VALUES (fila.idcentrodebitofacturaprestador, fila.idcentroinformefacturacion, fila.iddebitofacturaprestador, fila.informefacturacionnotadebitocc, fila.nroinforme);
    END IF;
    RETURN fila;
    END;
    $function$
