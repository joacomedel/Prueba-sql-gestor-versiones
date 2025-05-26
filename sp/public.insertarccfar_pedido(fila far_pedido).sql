CREATE OR REPLACE FUNCTION public.insertarccfar_pedido(fila far_pedido)
 RETURNS far_pedido
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_pedidocc:= current_timestamp;
    UPDATE sincro.far_pedido SET far_pedidocc= fila.far_pedidocc, idcentropedido= fila.idcentropedido, idpedido= fila.idpedido, idprestador= fila.idprestador, pedescripcion= fila.pedescripcion, pefechacreacion= fila.pefechacreacion, pfechadesde= fila.pfechadesde, pfechahasta= fila.pfechahasta, pidusuariocarga= fila.pidusuariocarga WHERE idcentropedido= fila.idcentropedido AND idpedido= fila.idpedido AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_pedido(far_pedidocc, idcentropedido, idpedido, idprestador, pedescripcion, pefechacreacion, pfechadesde, pfechahasta, pidusuariocarga) VALUES (fila.far_pedidocc, fila.idcentropedido, fila.idpedido, fila.idprestador, fila.pedescripcion, fila.pefechacreacion, fila.pfechadesde, fila.pfechahasta, fila.pidusuariocarga);
    END IF;
    RETURN fila;
    END;
    $function$
