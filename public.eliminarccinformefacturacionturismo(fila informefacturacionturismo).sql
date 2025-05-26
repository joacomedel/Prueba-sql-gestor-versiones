CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacionturismo(fila informefacturacionturismo)
 RETURNS informefacturacionturismo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionturismocc:= current_timestamp;
    delete from sincro.informefacturacionturismo WHERE idcentroinformefacturacion= fila.idcentroinformefacturacion AND nroinforme= fila.nroinforme AND TRUE;
    RETURN fila;
    END;
    $function$
