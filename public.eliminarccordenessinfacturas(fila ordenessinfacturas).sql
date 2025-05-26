CREATE OR REPLACE FUNCTION public.eliminarccordenessinfacturas(fila ordenessinfacturas)
 RETURNS ordenessinfacturas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenessinfacturascc:= current_timestamp;
    delete from sincro.ordenessinfacturas WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
