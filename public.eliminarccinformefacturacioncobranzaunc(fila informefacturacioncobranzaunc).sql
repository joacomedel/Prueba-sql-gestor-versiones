CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacioncobranzaunc(fila informefacturacioncobranzaunc)
 RETURNS informefacturacioncobranzaunc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacioncobranzaunccc:= current_timestamp;
    delete from sincro.informefacturacioncobranzaunc WHERE idcentroinformefacturacion= fila.idcentroinformefacturacion AND nroinforme= fila.nroinforme AND TRUE;
    RETURN fila;
    END;
    $function$
