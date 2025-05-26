CREATE OR REPLACE FUNCTION public.insertarcccatalogocomprobante(fila catalogocomprobante)
 RETURNS catalogocomprobante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.catalogocomprobantecc:= current_timestamp;
    UPDATE sincro.catalogocomprobante SET catalogocomprobantecc= fila.catalogocomprobantecc, ccactivo= fila.ccactivo, ccfechaemision= fila.ccfechaemision, ccfechaingreso= fila.ccfechaingreso, ccletra= fila.ccletra, ccmonto= fila.ccmonto, ccnrocomprobante= fila.ccnrocomprobante, ccoriginal= fila.ccoriginal, ccpuntodeventa= fila.ccpuntodeventa, cctipofactura= fila.cctipofactura, idcatalogocomprobante= fila.idcatalogocomprobante, idcentrocatalogocomprobante= fila.idcentrocatalogocomprobante, idprestador= fila.idprestador, idtipocomprobante= fila.idtipocomprobante, idusuario= fila.idusuario WHERE idcatalogocomprobante= fila.idcatalogocomprobante AND idcentrocatalogocomprobante= fila.idcentrocatalogocomprobante AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.catalogocomprobante(catalogocomprobantecc, ccactivo, ccfechaemision, ccfechaingreso, ccletra, ccmonto, ccnrocomprobante, ccoriginal, ccpuntodeventa, cctipofactura, idcatalogocomprobante, idcentrocatalogocomprobante, idprestador, idtipocomprobante, idusuario) VALUES (fila.catalogocomprobantecc, fila.ccactivo, fila.ccfechaemision, fila.ccfechaingreso, fila.ccletra, fila.ccmonto, fila.ccnrocomprobante, fila.ccoriginal, fila.ccpuntodeventa, fila.cctipofactura, fila.idcatalogocomprobante, fila.idcentrocatalogocomprobante, fila.idprestador, fila.idtipocomprobante, fila.idusuario);
    END IF;
    RETURN fila;
    END;
    $function$
