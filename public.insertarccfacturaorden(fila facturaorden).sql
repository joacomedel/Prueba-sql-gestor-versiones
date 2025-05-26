CREATE OR REPLACE FUNCTION public.insertarccfacturaorden(fila facturaorden)
 RETURNS facturaorden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaordencc:= current_timestamp;
    UPDATE sincro.facturaorden SET centro= fila.centro, facturaordencc= fila.facturaordencc, idcomprobantetipos= fila.idcomprobantetipos, nrofactura= fila.nrofactura, nroorden= fila.nroorden, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE centro= fila.centro AND idcomprobantetipos= fila.idcomprobantetipos AND nrofactura= fila.nrofactura AND nroorden= fila.nroorden AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaorden(centro, facturaordencc, idcomprobantetipos, nrofactura, nroorden, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.centro, fila.facturaordencc, fila.idcomprobantetipos, fila.nrofactura, fila.nroorden, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
