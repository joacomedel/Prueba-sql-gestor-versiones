CREATE OR REPLACE FUNCTION public.insertarccfar_liquidacionitemfvc(fila far_liquidacionitemfvc)
 RETURNS far_liquidacionitemfvc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionitemfvccc:= current_timestamp;
    UPDATE sincro.far_liquidacionitemfvc SET centro= fila.centro, far_liquidacionitemfvccc= fila.far_liquidacionitemfvccc, idcentroliquidacionitem= fila.idcentroliquidacionitem, idfacturacupon= fila.idfacturacupon, idliquidacionitem= fila.idliquidacionitem, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE centro= fila.centro AND idfacturacupon= fila.idfacturacupon AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_liquidacionitemfvc(centro, far_liquidacionitemfvccc, idcentroliquidacionitem, idfacturacupon, idliquidacionitem, nrofactura, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.centro, fila.far_liquidacionitemfvccc, fila.idcentroliquidacionitem, fila.idfacturacupon, fila.idliquidacionitem, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
