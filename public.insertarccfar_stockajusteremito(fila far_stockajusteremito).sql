CREATE OR REPLACE FUNCTION public.insertarccfar_stockajusteremito(fila far_stockajusteremito)
 RETURNS far_stockajusteremito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteremitocc:= current_timestamp;
    UPDATE sincro.far_stockajusteremito SET far_stockajusteremitocc= fila.far_stockajusteremitocc, idcentrostockajuste= fila.idcentrostockajuste, idstockajuste= fila.idstockajuste, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, sardescripcion= fila.sardescripcion, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idcentrostockajuste= fila.idcentrostockajuste AND idstockajuste= fila.idstockajuste AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_stockajusteremito(far_stockajusteremitocc, idcentrostockajuste, idstockajuste, nrofactura, nrosucursal, sardescripcion, tipocomprobante, tipofactura) VALUES (fila.far_stockajusteremitocc, fila.idcentrostockajuste, fila.idstockajuste, fila.nrofactura, fila.nrosucursal, fila.sardescripcion, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
