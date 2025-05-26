CREATE OR REPLACE FUNCTION public.eliminarccitemfacturaventa(fila itemfacturaventa)
 RETURNS itemfacturaventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.itemfacturaventacc:= current_timestamp;
    delete from sincro.itemfacturaventa WHERE iditem= fila.iditem AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
