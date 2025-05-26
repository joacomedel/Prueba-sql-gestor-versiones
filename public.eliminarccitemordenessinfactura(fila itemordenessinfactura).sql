CREATE OR REPLACE FUNCTION public.eliminarccitemordenessinfactura(fila itemordenessinfactura)
 RETURNS itemordenessinfactura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.itemordenessinfacturacc:= current_timestamp;
    delete from sincro.itemordenessinfactura WHERE centro= fila.centro AND idconcepto= fila.idconcepto AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
