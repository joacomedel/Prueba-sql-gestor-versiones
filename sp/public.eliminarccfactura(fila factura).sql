CREATE OR REPLACE FUNCTION public.eliminarccfactura(fila factura)
 RETURNS factura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturacc:= current_timestamp;
    delete from sincro.factura WHERE nroregistro= fila.nroregistro AND anio= fila.anio AND TRUE;
    RETURN fila;
    END;
    $function$
