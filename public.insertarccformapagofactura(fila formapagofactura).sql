CREATE OR REPLACE FUNCTION public.insertarccformapagofactura(fila formapagofactura)
 RETURNS formapagofactura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.formapagofacturacc:= current_timestamp;
    UPDATE sincro.formapagofactura SET formapagofacturacc= fila.formapagofacturacc, idformapago= fila.idformapago, nrocomprobante= fila.nrocomprobante, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idformapago= fila.idformapago AND nrocomprobante= fila.nrocomprobante AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.formapagofactura(formapagofacturacc, idformapago, nrocomprobante, nrofactura, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.formapagofacturacc, fila.idformapago, fila.nrocomprobante, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
