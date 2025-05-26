CREATE OR REPLACE FUNCTION public.eliminarccfacturaventacupon(fila facturaventacupon)
 RETURNS facturaventacupon
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventacuponcc:= current_timestamp;
    delete from sincro.facturaventacupon WHERE idfacturacupon= fila.idfacturacupon AND centro= fila.centro AND nrofactura= fila.nrofactura AND tipofactura= fila.tipofactura AND tipocomprobante= fila.tipocomprobante AND nrosucursal= fila.nrosucursal AND TRUE;
    RETURN fila;
    END;
    $function$
