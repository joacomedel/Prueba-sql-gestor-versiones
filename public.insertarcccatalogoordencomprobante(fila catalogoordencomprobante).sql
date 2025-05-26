CREATE OR REPLACE FUNCTION public.insertarcccatalogoordencomprobante(fila catalogoordencomprobante)
 RETURNS catalogoordencomprobante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.catalogoordencomprobantecc:= current_timestamp;
    UPDATE sincro.catalogoordencomprobante SET catalogoordencomprobantecc= fila.catalogoordencomprobantecc, centro= fila.centro, cocfechaingreso= fila.cocfechaingreso, idcatalogocomprobante= fila.idcatalogocomprobante, idcatalogoordencomprobante= fila.idcatalogoordencomprobante, idcentrocatalogocomprobante= fila.idcentrocatalogocomprobante, idcentrocatalogoordencomprobante= fila.idcentrocatalogoordencomprobante, idusuario= fila.idusuario, nroorden= fila.nroorden WHERE idcatalogoordencomprobante= fila.idcatalogoordencomprobante AND idcentrocatalogoordencomprobante= fila.idcentrocatalogoordencomprobante AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.catalogoordencomprobante(catalogoordencomprobantecc, centro, cocfechaingreso, idcatalogocomprobante, idcatalogoordencomprobante, idcentrocatalogocomprobante, idcentrocatalogoordencomprobante, idusuario, nroorden) VALUES (fila.catalogoordencomprobantecc, fila.centro, fila.cocfechaingreso, fila.idcatalogocomprobante, fila.idcatalogoordencomprobante, fila.idcentrocatalogocomprobante, fila.idcentrocatalogoordencomprobante, fila.idusuario, fila.nroorden);
    END IF;
    RETURN fila;
    END;
    $function$
