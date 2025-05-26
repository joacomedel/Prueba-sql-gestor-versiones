CREATE OR REPLACE FUNCTION public.insertarccfar_precargarpedidocomprobantearticulo(fila far_precargarpedidocomprobantearticulo)
 RETURNS far_precargarpedidocomprobantearticulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidocomprobantearticulocc:= current_timestamp;
    UPDATE sincro.far_precargarpedidocomprobantearticulo SET far_precargarpedidocomprobantearticulocc= fila.far_precargarpedidocomprobantearticulocc, idcentroprecargapedido= fila.idcentroprecargapedido, idcentroprecargarpedidocompcatalogo= fila.idcentroprecargarpedidocompcatalogo, idcentroprecargarpedidocomprobantearticulo= fila.idcentroprecargarpedidocomprobantearticulo, idcentropreciocompra= fila.idcentropreciocompra, idprecargarpedido= fila.idprecargarpedido, idprecargarpedidocompcatalogo= fila.idprecargarpedidocompcatalogo, idprecargarpedidocomprobantearticulo= fila.idprecargarpedidocomprobantearticulo, idpreciocompra= fila.idpreciocompra, pcpcacantidad= fila.pcpcacantidad, pcpcapreciocompra= fila.pcpcapreciocompra WHERE idprecargarpedidocomprobantearticulo= fila.idprecargarpedidocomprobantearticulo AND idcentroprecargarpedidocomprobantearticulo= fila.idcentroprecargarpedidocomprobantearticulo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precargarpedidocomprobantearticulo(far_precargarpedidocomprobantearticulocc, idcentroprecargapedido, idcentroprecargarpedidocompcatalogo, idcentroprecargarpedidocomprobantearticulo, idcentropreciocompra, idprecargarpedido, idprecargarpedidocompcatalogo, idprecargarpedidocomprobantearticulo, idpreciocompra, pcpcacantidad, pcpcapreciocompra) VALUES (fila.far_precargarpedidocomprobantearticulocc, fila.idcentroprecargapedido, fila.idcentroprecargarpedidocompcatalogo, fila.idcentroprecargarpedidocomprobantearticulo, fila.idcentropreciocompra, fila.idprecargarpedido, fila.idprecargarpedidocompcatalogo, fila.idprecargarpedidocomprobantearticulo, fila.idpreciocompra, fila.pcpcacantidad, fila.pcpcapreciocompra);
    END IF;
    RETURN fila;
    END;
    $function$
