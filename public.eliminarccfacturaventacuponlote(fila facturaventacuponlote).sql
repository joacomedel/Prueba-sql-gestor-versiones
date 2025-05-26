CREATE OR REPLACE FUNCTION public.eliminarccfacturaventacuponlote(fila facturaventacuponlote)
 RETURNS facturaventacuponlote
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventacuponlotecc:= current_timestamp;
    delete from sincro.facturaventacuponlote WHERE idfacturacupon= fila.idfacturacupon AND centro= fila.centro AND nrofactura= fila.nrofactura AND tipofactura= fila.tipofactura AND tipocomprobante= fila.tipocomprobante AND nrosucursal= fila.nrosucursal AND TRUE;
    RETURN fila;
    END;
    $function$
