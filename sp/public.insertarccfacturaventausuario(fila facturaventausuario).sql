CREATE OR REPLACE FUNCTION public.insertarccfacturaventausuario(fila facturaventausuario)
 RETURNS facturaventausuario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventausuariocc:= current_timestamp;
    UPDATE sincro.facturaventausuario SET facturaventausuariocc= fila.facturaventausuariocc, idusuario= fila.idusuario, nrofactura= fila.nrofactura, nrofacturafiscal= fila.nrofacturafiscal, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaventausuario(facturaventausuariocc, idusuario, nrofactura, nrofacturafiscal, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.facturaventausuariocc, fila.idusuario, fila.nrofactura, fila.nrofacturafiscal, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
