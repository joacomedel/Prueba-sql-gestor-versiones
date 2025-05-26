CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacionestado(fila informefacturacionestado)
 RETURNS informefacturacionestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionestadocc:= current_timestamp;
    delete from sincro.informefacturacionestado WHERE idinformefacturacionestado= fila.idinformefacturacionestado AND nroinforme= fila.nroinforme AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND TRUE;
    RETURN fila;
    END;
    $function$
