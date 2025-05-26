CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaitemitemfacturaventa(fila far_ordenventaitemitemfacturaventa)
 RETURNS far_ordenventaitemitemfacturaventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemitemfacturaventacc:= current_timestamp;
    UPDATE sincro.far_ordenventaitemitemfacturaventa SET far_ordenventaitemitemfacturaventacc= fila.far_ordenventaitemitemfacturaventacc, idcentroordenventaitem= fila.idcentroordenventaitem, iditem= fila.iditem, idordenventaitem= fila.idordenventaitem, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, ovcantdevueltas= fila.ovcantdevueltas, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idcentroordenventaitem= fila.idcentroordenventaitem AND iditem= fila.iditem AND idordenventaitem= fila.idordenventaitem AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaitemitemfacturaventa(far_ordenventaitemitemfacturaventacc, idcentroordenventaitem, iditem, idordenventaitem, nrofactura, nrosucursal, ovcantdevueltas, tipocomprobante, tipofactura) VALUES (fila.far_ordenventaitemitemfacturaventacc, fila.idcentroordenventaitem, fila.iditem, fila.idordenventaitem, fila.nrofactura, fila.nrosucursal, fila.ovcantdevueltas, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
