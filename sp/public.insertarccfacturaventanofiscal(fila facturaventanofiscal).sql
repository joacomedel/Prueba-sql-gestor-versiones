CREATE OR REPLACE FUNCTION public.insertarccfacturaventanofiscal(fila facturaventanofiscal)
 RETURNS facturaventanofiscal
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventanofiscalcc:= current_timestamp;
    UPDATE sincro.facturaventanofiscal SET facturaventanofiscalcc= fila.facturaventanofiscalcc, fvnffechaemision= fila.fvnffechaemision, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaventanofiscal(facturaventanofiscalcc, fvnffechaemision, nrofactura, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.facturaventanofiscalcc, fila.fvnffechaemision, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
