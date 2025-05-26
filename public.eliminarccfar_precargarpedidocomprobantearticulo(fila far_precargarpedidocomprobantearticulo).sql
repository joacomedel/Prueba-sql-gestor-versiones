CREATE OR REPLACE FUNCTION public.eliminarccfar_precargarpedidocomprobantearticulo(fila far_precargarpedidocomprobantearticulo)
 RETURNS far_precargarpedidocomprobantearticulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidocomprobantearticulocc:= current_timestamp;
    delete from sincro.far_precargarpedidocomprobantearticulo WHERE idprecargarpedidocomprobantearticulo= fila.idprecargarpedidocomprobantearticulo AND idcentroprecargarpedidocomprobantearticulo= fila.idcentroprecargarpedidocomprobantearticulo AND TRUE;
    RETURN fila;
    END;
    $function$
