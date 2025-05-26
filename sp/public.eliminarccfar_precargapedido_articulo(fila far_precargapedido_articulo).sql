CREATE OR REPLACE FUNCTION public.eliminarccfar_precargapedido_articulo(fila far_precargapedido_articulo)
 RETURNS far_precargapedido_articulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargapedido_articulocc:= current_timestamp;
    delete from sincro.far_precargapedido_articulo WHERE idprecargacomprobante= fila.idprecargacomprobante AND TRUE;
    RETURN fila;
    END;
    $function$
