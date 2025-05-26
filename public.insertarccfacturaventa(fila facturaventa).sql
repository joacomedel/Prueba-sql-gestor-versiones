CREATE OR REPLACE FUNCTION public.insertarccfacturaventa(fila facturaventa)
 RETURNS facturaventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventacc:= current_timestamp;
    UPDATE sincro.facturaventa SET anulada= fila.anulada, barra= fila.barra, centro= fila.centro, ctacontable= fila.ctacontable, facturaventacc= fila.facturaventacc, fechacreacion= fila.fechacreacion, fechaemision= fila.fechaemision, formapago= fila.formapago, importeamuc= fila.importeamuc, importecredito= fila.importecredito, importectacte= fila.importectacte, importedebito= fila.importedebito, importeefectivo= fila.importeefectivo, importesosunc= fila.importesosunc, nrodoc= fila.nrodoc, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipodoc= fila.tipodoc, tipofactura= fila.tipofactura WHERE nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaventa(anulada, barra, centro, ctacontable, facturaventacc, fechacreacion, fechaemision, formapago, importeamuc, importecredito, importectacte, importedebito, importeefectivo, importesosunc, nrodoc, nrofactura, nrosucursal, tipocomprobante, tipodoc, tipofactura) VALUES (fila.anulada, fila.barra, fila.centro, fila.ctacontable, fila.facturaventacc, fila.fechacreacion, fila.fechaemision, fila.formapago, fila.importeamuc, fila.importecredito, fila.importectacte, fila.importedebito, fila.importeefectivo, fila.importesosunc, fila.nrodoc, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipodoc, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
