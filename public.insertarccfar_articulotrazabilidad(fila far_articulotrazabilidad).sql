CREATE OR REPLACE FUNCTION public.insertarccfar_articulotrazabilidad(fila far_articulotrazabilidad)
 RETURNS far_articulotrazabilidad
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulotrazabilidadcc:= current_timestamp;
    UPDATE sincro.far_articulotrazabilidad SET idpedidoitem= fila.idpedidoitem, idcentroarticulocomprobantecompra= fila.idcentroarticulocomprobantecompra, idcentroprecargapedido= fila.idcentroprecargapedido, atcodigotrazabilidad= fila.atcodigotrazabilidad, idcentroordenventaitem= fila.idcentroordenventaitem, idcentroarticulotraza= fila.idcentroarticulotraza, idprecargarpedido= fila.idprecargarpedido, atlote= fila.atlote, far_articulotrazabilidadcc= fila.far_articulotrazabilidadcc, idarticulotraza= fila.idarticulotraza, idcentroarticulo= fila.idcentroarticulo, atserie= fila.atserie, atvencimiento= fila.atvencimiento, idarticulo= fila.idarticulo, idcentropedidoitem= fila.idcentropedidoitem, idarticulocomprobantecompra= fila.idarticulocomprobantecompra, idobrasocial= fila.idobrasocial, idcentroprecargarpedidocompcatalogo= fila.idcentroprecargarpedidocompcatalogo, tipodoc= fila.tipodoc, nrodoc= fila.nrodoc, idprecargarpedidocompcatalogo= fila.idprecargarpedidocompcatalogo, atcodigobarragtin= fila.atcodigobarragtin, idordenventaitem= fila.idordenventaitem WHERE idarticulotraza= fila.idarticulotraza AND idcentroarticulotraza= fila.idcentroarticulotraza AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_articulotrazabilidad(idpedidoitem, idcentroarticulocomprobantecompra, idcentroprecargapedido, atcodigotrazabilidad, idcentroordenventaitem, idcentroarticulotraza, idprecargarpedido, atlote, far_articulotrazabilidadcc, idarticulotraza, idcentroarticulo, atserie, atvencimiento, idarticulo, idcentropedidoitem, idarticulocomprobantecompra, idobrasocial, idcentroprecargarpedidocompcatalogo, tipodoc, nrodoc, idprecargarpedidocompcatalogo, atcodigobarragtin, idordenventaitem) VALUES (fila.idpedidoitem, fila.idcentroarticulocomprobantecompra, fila.idcentroprecargapedido, fila.atcodigotrazabilidad, fila.idcentroordenventaitem, fila.idcentroarticulotraza, fila.idprecargarpedido, fila.atlote, fila.far_articulotrazabilidadcc, fila.idarticulotraza, fila.idcentroarticulo, fila.atserie, fila.atvencimiento, fila.idarticulo, fila.idcentropedidoitem, fila.idarticulocomprobantecompra, fila.idobrasocial, fila.idcentroprecargarpedidocompcatalogo, fila.tipodoc, fila.nrodoc, fila.idprecargarpedidocompcatalogo, fila.atcodigobarragtin, fila.idordenventaitem);
    END IF;
    RETURN fila;
    END;
    $function$
