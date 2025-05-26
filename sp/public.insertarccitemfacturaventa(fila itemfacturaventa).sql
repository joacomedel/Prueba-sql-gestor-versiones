CREATE OR REPLACE FUNCTION public.insertarccitemfacturaventa(fila itemfacturaventa)
 RETURNS itemfacturaventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.itemfacturaventacc:= current_timestamp;
    UPDATE sincro.itemfacturaventa SET cantidad= fila.cantidad, descripcion= fila.descripcion, idconcepto= fila.idconcepto, iditem= fila.iditem, idiva= fila.idiva, importe= fila.importe, itemfacturaventacc= fila.itemfacturaventacc, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE iditem= fila.iditem AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.itemfacturaventa(cantidad, descripcion, idconcepto, iditem, idiva, importe, itemfacturaventacc, nrofactura, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.cantidad, fila.descripcion, fila.idconcepto, fila.iditem, fila.idiva, fila.importe, fila.itemfacturaventacc, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
