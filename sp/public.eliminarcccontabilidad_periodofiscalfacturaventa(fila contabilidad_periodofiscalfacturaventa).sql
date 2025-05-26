CREATE OR REPLACE FUNCTION public.eliminarcccontabilidad_periodofiscalfacturaventa(fila contabilidad_periodofiscalfacturaventa)
 RETURNS contabilidad_periodofiscalfacturaventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.contabilidad_periodofiscalfacturaventacc:= current_timestamp;
    delete from sincro.contabilidad_periodofiscalfacturaventa WHERE nrofactura= fila.nrofactura AND tipofactura= fila.tipofactura AND idperiodofiscal= fila.idperiodofiscal AND tipocomprobante= fila.tipocomprobante AND nrosucursal= fila.nrosucursal AND TRUE;
    RETURN fila;
    END;
    $function$
