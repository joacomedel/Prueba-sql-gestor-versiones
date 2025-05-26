CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacion(fila informefacturacion)
 RETURNS informefacturacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacioncc:= current_timestamp;
    delete from sincro.informefacturacion WHERE idcentroinformefacturacion= fila.idcentroinformefacturacion AND nroinforme= fila.nroinforme AND TRUE;
    RETURN fila;
    END;
    $function$
