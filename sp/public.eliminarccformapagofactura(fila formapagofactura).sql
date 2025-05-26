CREATE OR REPLACE FUNCTION public.eliminarccformapagofactura(fila formapagofactura)
 RETURNS formapagofactura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.formapagofacturacc:= current_timestamp;
    delete from sincro.formapagofactura WHERE idformapago= fila.idformapago AND nrocomprobante= fila.nrocomprobante AND TRUE;
    RETURN fila;
    END;
    $function$
