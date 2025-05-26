CREATE OR REPLACE FUNCTION public.insertarccfar_oviiformapago(fila far_oviiformapago)
 RETURNS far_oviiformapago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_oviiformapagocc:= current_timestamp;
    UPDATE sincro.far_oviiformapago SET far_oviiformapagocc= fila.far_oviiformapagocc, idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte, idcentrooviiformapago= fila.idcentrooviiformapago, idordenventaitemimporte= fila.idordenventaitemimporte, idoviiformapago= fila.idoviiformapago, idvalorescaja= fila.idvalorescaja, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, oviifpcantcuotas= fila.oviifpcantcuotas, oviifpmonto= fila.oviifpmonto, oviifpmontocuota= fila.oviifpmontocuota, oviifpmontodto= fila.oviifpmontodto, oviifpporcentajedto= fila.oviifpporcentajedto, oviifpporcentajeinteres= fila.oviifpporcentajeinteres, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idcentrooviiformapago= fila.idcentrooviiformapago AND idoviiformapago= fila.idoviiformapago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_oviiformapago(far_oviiformapagocc, idcentroordenventaitemimporte, idcentrooviiformapago, idordenventaitemimporte, idoviiformapago, idvalorescaja, nrofactura, nrosucursal, oviifpcantcuotas, oviifpmonto, oviifpmontocuota, oviifpmontodto, oviifpporcentajedto, oviifpporcentajeinteres, tipocomprobante, tipofactura) VALUES (fila.far_oviiformapagocc, fila.idcentroordenventaitemimporte, fila.idcentrooviiformapago, fila.idordenventaitemimporte, fila.idoviiformapago, fila.idvalorescaja, fila.nrofactura, fila.nrosucursal, fila.oviifpcantcuotas, fila.oviifpmonto, fila.oviifpmontocuota, fila.oviifpmontodto, fila.oviifpporcentajedto, fila.oviifpporcentajeinteres, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
