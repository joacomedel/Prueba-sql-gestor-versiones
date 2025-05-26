CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacionliqfarmacia(fila informefacturacionliqfarmacia)
 RETURNS informefacturacionliqfarmacia
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionliqfarmaciacc:= current_timestamp;
    delete from sincro.informefacturacionliqfarmacia WHERE nroinforme= fila.nroinforme AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND TRUE;
    RETURN fila;
    END;
    $function$
