CREATE OR REPLACE FUNCTION public.eliminarccfacturaorden(fila facturaorden)
 RETURNS facturaorden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaordencc:= current_timestamp;
    delete from sincro.facturaorden WHERE centro= fila.centro AND idcomprobantetipos= fila.idcomprobantetipos AND nrofactura= fila.nrofactura AND nroorden= fila.nroorden AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
