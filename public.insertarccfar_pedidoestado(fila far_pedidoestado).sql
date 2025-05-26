CREATE OR REPLACE FUNCTION public.insertarccfar_pedidoestado(fila far_pedidoestado)
 RETURNS far_pedidoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_pedidoestadocc:= current_timestamp;
    UPDATE sincro.far_pedidoestado SET far_pedidoestadocc= fila.far_pedidoestadocc, idcentropedido= fila.idcentropedido, idcentropedidoestado= fila.idcentropedidoestado, idestadotipo= fila.idestadotipo, idpedido= fila.idpedido, idpedidoestado= fila.idpedidoestado, pefechafin= fila.pefechafin, pefechaini= fila.pefechaini, peidusuario= fila.peidusuario WHERE idpedidoestado= fila.idpedidoestado AND idcentropedidoestado= fila.idcentropedidoestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_pedidoestado(far_pedidoestadocc, idcentropedido, idcentropedidoestado, idestadotipo, idpedido, idpedidoestado, pefechafin, pefechaini, peidusuario) VALUES (fila.far_pedidoestadocc, fila.idcentropedido, fila.idcentropedidoestado, fila.idestadotipo, fila.idpedido, fila.idpedidoestado, fila.pefechafin, fila.pefechaini, fila.peidusuario);
    END IF;
    RETURN fila;
    END;
    $function$
