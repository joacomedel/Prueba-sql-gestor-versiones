CREATE OR REPLACE FUNCTION public.insertarccfacturaventacuponestado(fila facturaventacuponestado)
 RETURNS facturaventacuponestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventacuponestadocc:= current_timestamp;
    UPDATE sincro.facturaventacuponestado SET centro= fila.centro, facturaventacuponestadocc= fila.facturaventacuponestadocc, fvcedescripcion= fila.fvcedescripcion, fvcefechafin= fila.fvcefechafin, fvcefechaini= fila.fvcefechaini, idcentrofacturaventacuponestado= fila.idcentrofacturaventacuponestado, idfacturacupon= fila.idfacturacupon, idfacturaventacuponestado= fila.idfacturaventacuponestado, idordenventaestadotipo= fila.idordenventaestadotipo, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idcentrofacturaventacuponestado= fila.idcentrofacturaventacuponestado AND idfacturaventacuponestado= fila.idfacturaventacuponestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaventacuponestado(centro, facturaventacuponestadocc, fvcedescripcion, fvcefechafin, fvcefechaini, idcentrofacturaventacuponestado, idfacturacupon, idfacturaventacuponestado, idordenventaestadotipo, nrofactura, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.centro, fila.facturaventacuponestadocc, fila.fvcedescripcion, fila.fvcefechafin, fila.fvcefechaini, fila.idcentrofacturaventacuponestado, fila.idfacturacupon, fila.idfacturaventacuponestado, fila.idordenventaestadotipo, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
