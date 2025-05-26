CREATE OR REPLACE FUNCTION public.insertarccfar_precargarpedido(fila far_precargarpedido)
 RETURNS far_precargarpedido
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidocc:= current_timestamp;
    UPDATE sincro.far_precargarpedido SET idusuario= fila.idusuario, pcpprecioventasiniva= fila.pcpprecioventasiniva, pcpprecioventaconiva= fila.pcpprecioventaconiva, idpedidoitem= fila.idpedidoitem, pcpfechacargar= fila.pcpfechacargar, idcentropedido= fila.idcentropedido, pcppreciocompra= fila.pcppreciocompra, idcentroprecargapedido= fila.idcentroprecargapedido, far_precargarpedidocc= fila.far_precargarpedidocc, idprecargarpedido= fila.idprecargarpedido, pcpcantidad= fila.pcpcantidad, idcentroarticulo= fila.idcentroarticulo, idpedido= fila.idpedido, idarticulo= fila.idarticulo WHERE idprecargarpedido= fila.idprecargarpedido AND idcentroprecargapedido= fila.idcentroprecargapedido AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precargarpedido(idusuario, pcpprecioventasiniva, pcpprecioventaconiva, idpedidoitem, pcpfechacargar, idcentropedido, pcppreciocompra, idcentroprecargapedido, far_precargarpedidocc, idprecargarpedido, pcpcantidad, idcentroarticulo, idpedido, idarticulo) VALUES (fila.idusuario, fila.pcpprecioventasiniva, fila.pcpprecioventaconiva, fila.idpedidoitem, fila.pcpfechacargar, fila.idcentropedido, fila.pcppreciocompra, fila.idcentroprecargapedido, fila.far_precargarpedidocc, fila.idprecargarpedido, fila.pcpcantidad, fila.idcentroarticulo, fila.idpedido, fila.idarticulo);
    END IF;
    RETURN fila;
    END;
    $function$
