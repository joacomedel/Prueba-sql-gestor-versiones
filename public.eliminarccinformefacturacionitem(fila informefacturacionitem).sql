CREATE OR REPLACE FUNCTION public.eliminarccinformefacturacionitem(fila informefacturacionitem)
 RETURNS informefacturacionitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacionitemcc:= current_timestamp;
    delete from sincro.informefacturacionitem WHERE idinformefacturacionitem= fila.idinformefacturacionitem AND idcentroinformefacturacionitem= fila.idcentroinformefacturacionitem AND TRUE;
    RETURN fila;
    END;
    $function$
