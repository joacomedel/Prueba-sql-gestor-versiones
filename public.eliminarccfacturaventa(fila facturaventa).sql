CREATE OR REPLACE FUNCTION public.eliminarccfacturaventa(fila facturaventa)
 RETURNS facturaventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventacc:= current_timestamp;
    delete from sincro.facturaventa WHERE nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
