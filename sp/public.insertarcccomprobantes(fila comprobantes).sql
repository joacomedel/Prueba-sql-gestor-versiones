CREATE OR REPLACE FUNCTION public.insertarcccomprobantes(fila comprobantes)
 RETURNS comprobantes
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.comprobantescc:= current_timestamp;
    UPDATE sincro.comprobantes SET cdescripcion= fila.cdescripcion, cfechacomprobante= fila.cfechacomprobante, cimporte= fila.cimporte, comprobantescc= fila.comprobantescc, idasientocontable= fila.idasientocontable, idasientoimputacion= fila.idasientoimputacion, idcentroregional= fila.idcentroregional, idcomprobantes= fila.idcomprobantes, idcomprobantetipos= fila.idcomprobantetipos, numerocomprobante= fila.numerocomprobante WHERE idcentroregional= fila.idcentroregional AND idcomprobantes= fila.idcomprobantes AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.comprobantes(cdescripcion, cfechacomprobante, cimporte, comprobantescc, idasientocontable, idasientoimputacion, idcentroregional, idcomprobantes, idcomprobantetipos, numerocomprobante) VALUES (fila.cdescripcion, fila.cfechacomprobante, fila.cimporte, fila.comprobantescc, fila.idasientocontable, fila.idasientoimputacion, fila.idcentroregional, fila.idcomprobantes, fila.idcomprobantetipos, fila.numerocomprobante);
    END IF;
    RETURN fila;
    END;
    $function$
