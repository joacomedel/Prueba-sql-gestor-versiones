CREATE OR REPLACE FUNCTION public.insertarccfacturaventa_quitardeliq(fila facturaventa_quitardeliq)
 RETURNS facturaventa_quitardeliq
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventa_quitardeliqcc:= current_timestamp;
    UPDATE sincro.facturaventa_quitardeliq SET centro= fila.centro, facturaventa_quitardeliqcc= fila.facturaventa_quitardeliqcc, fechainsercion= fila.fechainsercion, idcentrofacturaventaquitardeliq= fila.idcentrofacturaventaquitardeliq, idcentroliquidacion= fila.idcentroliquidacion, idfacturaventaquitardeliq= fila.idfacturaventaquitardeliq, idliquidacion= fila.idliquidacion, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idcentrofacturaventaquitardeliq= fila.idcentrofacturaventaquitardeliq AND idfacturaventaquitardeliq= fila.idfacturaventaquitardeliq AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaventa_quitardeliq(centro, facturaventa_quitardeliqcc, fechainsercion, idcentrofacturaventaquitardeliq, idcentroliquidacion, idfacturaventaquitardeliq, idliquidacion, nrofactura, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.centro, fila.facturaventa_quitardeliqcc, fila.fechainsercion, fila.idcentrofacturaventaquitardeliq, fila.idcentroliquidacion, fila.idfacturaventaquitardeliq, fila.idliquidacion, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
