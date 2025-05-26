CREATE OR REPLACE FUNCTION public.insertarccfar_precargarpedidocomprobante(fila far_precargarpedidocomprobante)
 RETURNS far_precargarpedidocomprobante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidocomprobantecc:= current_timestamp;
    UPDATE sincro.far_precargarpedidocomprobante SET anio= fila.anio, far_precargarpedidocomprobantecc= fila.far_precargarpedidocomprobantecc, fechaemision= fila.fechaemision, idcentroprecargapedido= fila.idcentroprecargapedido, idcentroprecargarpedidocompcatalogo= fila.idcentroprecargarpedidocompcatalogo, idprecargarpedido= fila.idprecargarpedido, idprecargarpedidocompcatalogo= fila.idprecargarpedidocompcatalogo, idprestador= fila.idprestador, idtipocomprobante= fila.idtipocomprobante, letra= fila.letra, numeroregistro= fila.numeroregistro, numfactura= fila.numfactura, tipofactura= fila.tipofactura WHERE idprecargarpedido= fila.idprecargarpedido AND idcentroprecargapedido= fila.idcentroprecargapedido AND idprecargarpedidocompcatalogo= fila.idprecargarpedidocompcatalogo AND idcentroprecargarpedidocompcatalogo= fila.idcentroprecargarpedidocompcatalogo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precargarpedidocomprobante(anio, far_precargarpedidocomprobantecc, fechaemision, idcentroprecargapedido, idcentroprecargarpedidocompcatalogo, idprecargarpedido, idprecargarpedidocompcatalogo, idprestador, idtipocomprobante, letra, numeroregistro, numfactura, tipofactura) VALUES (fila.anio, fila.far_precargarpedidocomprobantecc, fila.fechaemision, fila.idcentroprecargapedido, fila.idcentroprecargarpedidocompcatalogo, fila.idprecargarpedido, fila.idprecargarpedidocompcatalogo, fila.idprestador, fila.idtipocomprobante, fila.letra, fila.numeroregistro, fila.numfactura, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
