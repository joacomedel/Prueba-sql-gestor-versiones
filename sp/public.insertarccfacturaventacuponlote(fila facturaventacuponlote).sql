CREATE OR REPLACE FUNCTION public.insertarccfacturaventacuponlote(fila facturaventacuponlote)
 RETURNS facturaventacuponlote
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventacuponlotecc:= current_timestamp;
    UPDATE sincro.facturaventacuponlote SET tipofactura= fila.tipofactura, idposnet= fila.idposnet, nrolote= fila.nrolote, nrofactura= fila.nrofactura, nrocomercio= fila.nrocomercio, tipocomprobante= fila.tipocomprobante, nrosucursal= fila.nrosucursal, idfacturacupon= fila.idfacturacupon, facturaventacuponlotecc= fila.facturaventacuponlotecc, centro= fila.centro WHERE idfacturacupon= fila.idfacturacupon AND centro= fila.centro AND nrofactura= fila.nrofactura AND tipofactura= fila.tipofactura AND tipocomprobante= fila.tipocomprobante AND nrosucursal= fila.nrosucursal AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaventacuponlote(tipofactura, idposnet, nrolote, nrofactura, nrocomercio, tipocomprobante, nrosucursal, idfacturacupon, facturaventacuponlotecc, centro) VALUES (fila.tipofactura, fila.idposnet, fila.nrolote, fila.nrofactura, fila.nrocomercio, fila.tipocomprobante, fila.nrosucursal, fila.idfacturacupon, fila.facturaventacuponlotecc, fila.centro);
    END IF;
    RETURN fila;
    END;
    $function$
