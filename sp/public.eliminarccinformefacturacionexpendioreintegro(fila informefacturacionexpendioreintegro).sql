CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacionexpendioreintegro(fila informefacturacionexpendioreintegro)
 RETURNS informefacturacionexpendioreintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionexpendioreintegrocc:= current_timestamp;
    delete from sincro.informefacturacionexpendioreintegro WHERE nroinforme= fila.nroinforme AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND TRUE;
    RETURN fila;
    END;
    $function$
