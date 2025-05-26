CREATE OR REPLACE FUNCTION public.insertarccinformefacturacion(fila informefacturacion)
 RETURNS informefacturacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacioncc:= current_timestamp;
    UPDATE sincro.informefacturacion SET barra= fila.barra, fechainforme= fila.fechainforme, idcentroinformefacturacion= fila.idcentroinformefacturacion, idformapagotipos= fila.idformapagotipos, idinformefacturaciontipo= fila.idinformefacturaciontipo, idtipofactura= fila.idtipofactura, informefacturacioncc= fila.informefacturacioncc, nrocliente= fila.nrocliente, nrofactura= fila.nrofactura, nroinforme= fila.nroinforme, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idcentroinformefacturacion= fila.idcentroinformefacturacion AND nroinforme= fila.nroinforme AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacion(barra, fechainforme, idcentroinformefacturacion, idformapagotipos, idinformefacturaciontipo, idtipofactura, informefacturacioncc, nrocliente, nrofactura, nroinforme, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.barra, fila.fechainforme, fila.idcentroinformefacturacion, fila.idformapagotipos, fila.idinformefacturaciontipo, fila.idtipofactura, fila.informefacturacioncc, fila.nrocliente, fila.nrofactura, fila.nroinforme, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
