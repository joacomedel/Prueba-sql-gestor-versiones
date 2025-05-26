CREATE OR REPLACE FUNCTION public.eliminarcccatalogoordencomprobante(fila catalogoordencomprobante)
 RETURNS catalogoordencomprobante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.catalogoordencomprobantecc:= current_timestamp;
    delete from sincro.catalogoordencomprobante WHERE idcatalogoordencomprobante= fila.idcatalogoordencomprobante AND idcentrocatalogoordencomprobante= fila.idcentrocatalogoordencomprobante AND TRUE;
    RETURN fila;
    END;
    $function$
