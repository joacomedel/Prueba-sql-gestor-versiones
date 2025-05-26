CREATE OR REPLACE FUNCTION public.insertarcccontabilidad_periodofiscalfacturaventa(fila contabilidad_periodofiscalfacturaventa)
 RETURNS contabilidad_periodofiscalfacturaventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.contabilidad_periodofiscalfacturaventacc:= current_timestamp;
    UPDATE sincro.contabilidad_periodofiscalfacturaventa SET tipofactura= fila.tipofactura, contabilidad_periodofiscalfacturaventacc= fila.contabilidad_periodofiscalfacturaventacc, nrosucursal= fila.nrosucursal, idperiodofiscal= fila.idperiodofiscal, nrofactura= fila.nrofactura, tipocomprobante= fila.tipocomprobante WHERE nrofactura= fila.nrofactura AND tipofactura= fila.tipofactura AND idperiodofiscal= fila.idperiodofiscal AND tipocomprobante= fila.tipocomprobante AND nrosucursal= fila.nrosucursal AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.contabilidad_periodofiscalfacturaventa(tipofactura, contabilidad_periodofiscalfacturaventacc, nrosucursal, idperiodofiscal, nrofactura, tipocomprobante) VALUES (fila.tipofactura, fila.contabilidad_periodofiscalfacturaventacc, fila.nrosucursal, fila.idperiodofiscal, fila.nrofactura, fila.tipocomprobante);
    END IF;
    RETURN fila;
    END;
    $function$
