CREATE OR REPLACE FUNCTION public.eliminarccfacturaventanofiscal(fila facturaventanofiscal)
 RETURNS facturaventanofiscal
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventanofiscalcc:= current_timestamp;
    delete from sincro.facturaventanofiscal WHERE nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
