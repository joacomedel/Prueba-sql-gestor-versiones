CREATE OR REPLACE FUNCTION public.insertarccfar_pedidoitems(fila far_pedidoitems)
 RETURNS far_pedidoitems
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_pedidoitemscc:= current_timestamp;
    UPDATE sincro.far_pedidoitems SET far_pedidoitemscc= fila.far_pedidoitemscc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentropedido= fila.idcentropedido, idcentropedidoitem= fila.idcentropedidoitem, idpedido= fila.idpedido, idpedidoitem= fila.idpedidoitem, picantidad= fila.picantidad, picantidadentregada= fila.picantidadentregada, picantvendido= fila.picantvendido, piidusuariocarga= fila.piidusuariocarga, piotrainformacion= fila.piotrainformacion WHERE idpedidoitem= fila.idpedidoitem AND idcentropedidoitem= fila.idcentropedidoitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_pedidoitems(far_pedidoitemscc, idarticulo, idcentroarticulo, idcentropedido, idcentropedidoitem, idpedido, idpedidoitem, picantidad, picantidadentregada, picantvendido, piidusuariocarga, piotrainformacion) VALUES (fila.far_pedidoitemscc, fila.idarticulo, fila.idcentroarticulo, fila.idcentropedido, fila.idcentropedidoitem, fila.idpedido, fila.idpedidoitem, fila.picantidad, fila.picantidadentregada, fila.picantvendido, fila.piidusuariocarga, fila.piotrainformacion);
    END IF;
    RETURN fila;
    END;
    $function$
