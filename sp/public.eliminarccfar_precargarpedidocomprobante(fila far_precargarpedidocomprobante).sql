CREATE OR REPLACE FUNCTION public.eliminarccfar_precargarpedidocomprobante(fila far_precargarpedidocomprobante)
 RETURNS far_precargarpedidocomprobante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidocomprobantecc:= current_timestamp;
    delete from sincro.far_precargarpedidocomprobante WHERE idprecargarpedido= fila.idprecargarpedido AND idcentroprecargapedido= fila.idcentroprecargapedido AND idprecargarpedidocompcatalogo= fila.idprecargarpedidocompcatalogo AND idcentroprecargarpedidocompcatalogo= fila.idcentroprecargarpedidocompcatalogo AND TRUE;
    RETURN fila;
    END;
    $function$
