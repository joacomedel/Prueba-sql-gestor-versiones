CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacionaporte(fila informefacturacionaporte)
 RETURNS informefacturacionaporte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionaportecc:= current_timestamp;
    delete from sincro.informefacturacionaporte WHERE idaporte= fila.idaporte AND idcentroinformefacturacion= fila.idcentroinformefacturacion AND idcentroregionaluso= fila.idcentroregionaluso AND nroinforme= fila.nroinforme AND TRUE;
    RETURN fila;
    END;
    $function$
