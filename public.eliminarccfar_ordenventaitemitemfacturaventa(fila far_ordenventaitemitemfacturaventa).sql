CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaitemitemfacturaventa(fila far_ordenventaitemitemfacturaventa)
 RETURNS far_ordenventaitemitemfacturaventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemitemfacturaventacc:= current_timestamp;
    delete from sincro.far_ordenventaitemitemfacturaventa WHERE idcentroordenventaitem= fila.idcentroordenventaitem AND iditem= fila.iditem AND idordenventaitem= fila.idordenventaitem AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
