CREATE OR REPLACE FUNCTION public.insertarccfar_precargarpedidocompcatalogo(fila far_precargarpedidocompcatalogo)
 RETURNS far_precargarpedidocompcatalogo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidocompcatalogocc:= current_timestamp;
    UPDATE sincro.far_precargarpedidocompcatalogo SET tipofactura= fila.tipofactura, idusuario= fila.idusuario, idcentroarchivostrazabilidad= fila.idcentroarchivostrazabilidad, idprecargarpedidocompcatalogo= fila.idprecargarpedidocompcatalogo, idtipocomprobante= fila.idtipocomprobante, idprestador= fila.idprestador, fechaemision= fila.fechaemision, idarchivostrazabilidad= fila.idarchivostrazabilidad, anio= fila.anio, numeroregistro= fila.numeroregistro, far_precargarpedidocompcatalogocc= fila.far_precargarpedidocompcatalogocc, numfactura= fila.numfactura, letra= fila.letra, idcentroprecargarpedidocompcatalogo= fila.idcentroprecargarpedidocompcatalogo, pcpccactivo= fila.pcpccactivo WHERE idprecargarpedidocompcatalogo= fila.idprecargarpedidocompcatalogo AND idcentroprecargarpedidocompcatalogo= fila.idcentroprecargarpedidocompcatalogo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precargarpedidocompcatalogo(tipofactura, idusuario, idcentroarchivostrazabilidad, idprecargarpedidocompcatalogo, idtipocomprobante, idprestador, fechaemision, idarchivostrazabilidad, anio, numeroregistro, far_precargarpedidocompcatalogocc, numfactura, letra, idcentroprecargarpedidocompcatalogo, pcpccactivo) VALUES (fila.tipofactura, fila.idusuario, fila.idcentroarchivostrazabilidad, fila.idprecargarpedidocompcatalogo, fila.idtipocomprobante, fila.idprestador, fila.fechaemision, fila.idarchivostrazabilidad, fila.anio, fila.numeroregistro, fila.far_precargarpedidocompcatalogocc, fila.numfactura, fila.letra, fila.idcentroprecargarpedidocompcatalogo, fila.pcpccactivo);
    END IF;
    RETURN fila;
    END;
    $function$
