CREATE OR REPLACE FUNCTION public.eliminarcccatalogocomprobante(fila catalogocomprobante)
 RETURNS catalogocomprobante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.catalogocomprobantecc:= current_timestamp;
    delete from sincro.catalogocomprobante WHERE idcatalogocomprobante= fila.idcatalogocomprobante AND idcentrocatalogocomprobante= fila.idcentrocatalogocomprobante AND TRUE;
    RETURN fila;
    END;
    $function$
