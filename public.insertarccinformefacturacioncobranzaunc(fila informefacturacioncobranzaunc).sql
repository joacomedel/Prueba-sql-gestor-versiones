CREATE OR REPLACE FUNCTION public.insertarccinformefacturacioncobranzaunc(fila informefacturacioncobranzaunc)
 RETURNS informefacturacioncobranzaunc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacioncobranzaunccc:= current_timestamp;
    UPDATE sincro.informefacturacioncobranzaunc SET idcentroinformefacturacion= fila.idcentroinformefacturacion, informefacturacioncobranzaunccc= fila.informefacturacioncobranzaunccc, nroinforme= fila.nroinforme WHERE idcentroinformefacturacion= fila.idcentroinformefacturacion AND nroinforme= fila.nroinforme AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacioncobranzaunc(idcentroinformefacturacion, informefacturacioncobranzaunccc, nroinforme) VALUES (fila.idcentroinformefacturacion, fila.informefacturacioncobranzaunccc, fila.nroinforme);
    END IF;
    RETURN fila;
    END;
    $function$
