CREATE OR REPLACE FUNCTION public.eliminarccfar_stockajusteremito(fila far_stockajusteremito)
 RETURNS far_stockajusteremito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteremitocc:= current_timestamp;
    delete from sincro.far_stockajusteremito WHERE idcentrostockajuste= fila.idcentrostockajuste AND idstockajuste= fila.idstockajuste AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
