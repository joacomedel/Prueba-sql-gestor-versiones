CREATE OR REPLACE FUNCTION public.insertarccfar_precargapedido_articulo(fila far_precargapedido_articulo)
 RETURNS far_precargapedido_articulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargapedido_articulocc:= current_timestamp;
    UPDATE sincro.far_precargapedido_articulo SET archivonombre= fila.archivonombre, cantidad= fila.cantidad, codigobarra= fila.codigobarra, far_precargapedido_articulocc= fila.far_precargapedido_articulocc, fechacarga= fila.fechacarga, fechauso= fila.fechauso, fila= fila.fila, idcentroprecargapedido= fila.idcentroprecargapedido, idprecargacomprobante= fila.idprecargacomprobante, idprecargarpedido= fila.idprecargarpedido, idusuario= fila.idusuario, preciocomprobante= fila.preciocomprobante, transaccion= fila.transaccion WHERE idprecargacomprobante= fila.idprecargacomprobante AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precargapedido_articulo(archivonombre, cantidad, codigobarra, far_precargapedido_articulocc, fechacarga, fechauso, fila, idcentroprecargapedido, idprecargacomprobante, idprecargarpedido, idusuario, preciocomprobante, transaccion) VALUES (fila.archivonombre, fila.cantidad, fila.codigobarra, fila.far_precargapedido_articulocc, fila.fechacarga, fila.fechauso, fila.fila, fila.idcentroprecargapedido, fila.idprecargacomprobante, fila.idprecargarpedido, fila.idusuario, fila.preciocomprobante, fila.transaccion);
    END IF;
    RETURN fila;
    END;
    $function$
