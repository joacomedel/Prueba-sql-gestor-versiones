CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacioncobranza(fila informefacturacioncobranza)
 RETURNS informefacturacioncobranza
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacioncobranzacc:= current_timestamp;
    delete from sincro.informefacturacioncobranza WHERE idcentroinformefacturacion= fila.idcentroinformefacturacion AND idformapagocobranza= fila.idformapagocobranza AND idpago= fila.idpago AND nroinforme= fila.nroinforme AND TRUE;
    RETURN fila;
    END;
    $function$
