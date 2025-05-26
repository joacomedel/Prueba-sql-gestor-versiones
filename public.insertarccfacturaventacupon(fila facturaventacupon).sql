CREATE OR REPLACE FUNCTION public.insertarccfacturaventacupon(fila facturaventacupon)
 RETURNS facturaventacupon
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventacuponcc:= current_timestamp;
    UPDATE sincro.facturaventacupon SET autorizacion= fila.autorizacion, centro= fila.centro, cuotas= fila.cuotas, facturaventacuponcc= fila.facturaventacuponcc, fvcporcentajedto= fila.fvcporcentajedto, idfacturacupon= fila.idfacturacupon, idvalorescaja= fila.idvalorescaja, monto= fila.monto, nrocupon= fila.nrocupon, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, nrotarjeta= fila.nrotarjeta, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idfacturacupon= fila.idfacturacupon AND centro= fila.centro AND nrofactura= fila.nrofactura AND tipofactura= fila.tipofactura AND tipocomprobante= fila.tipocomprobante AND nrosucursal= fila.nrosucursal AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaventacupon(autorizacion, centro, cuotas, facturaventacuponcc, fvcporcentajedto, idfacturacupon, idvalorescaja, monto, nrocupon, nrofactura, nrosucursal, nrotarjeta, tipocomprobante, tipofactura) VALUES (fila.autorizacion, fila.centro, fila.cuotas, fila.facturaventacuponcc, fila.fvcporcentajedto, fila.idfacturacupon, fila.idvalorescaja, fila.monto, fila.nrocupon, fila.nrofactura, fila.nrosucursal, fila.nrotarjeta, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
