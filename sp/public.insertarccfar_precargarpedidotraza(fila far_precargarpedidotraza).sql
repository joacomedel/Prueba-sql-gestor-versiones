CREATE OR REPLACE FUNCTION public.insertarccfar_precargarpedidotraza(fila far_precargarpedidotraza)
 RETURNS far_precargarpedidotraza
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidotrazacc:= current_timestamp;
    UPDATE sincro.far_precargarpedidotraza SET atcodigobarragtin= fila.atcodigobarragtin, idcentroprecargarpedidotraza= fila.idcentroprecargarpedidotraza, idprecargarpedidotraza= fila.idprecargarpedidotraza, idcentroprecargapedido= fila.idcentroprecargapedido, atcodigotrazabilidad= fila.atcodigotrazabilidad, far_precargarpedidotrazacc= fila.far_precargarpedidotrazacc, idprecargarpedido= fila.idprecargarpedido, atlote= fila.atlote, pptborrado= fila.pptborrado, atserie= fila.atserie, atvencimiento= fila.atvencimiento WHERE idprecargarpedidotraza= fila.idprecargarpedidotraza AND idcentroprecargarpedidotraza= fila.idcentroprecargarpedidotraza AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precargarpedidotraza(atcodigobarragtin, idcentroprecargarpedidotraza, idprecargarpedidotraza, idcentroprecargapedido, atcodigotrazabilidad, far_precargarpedidotrazacc, idprecargarpedido, atlote, pptborrado, atserie, atvencimiento) VALUES (fila.atcodigobarragtin, fila.idcentroprecargarpedidotraza, fila.idprecargarpedidotraza, fila.idcentroprecargapedido, fila.atcodigotrazabilidad, fila.far_precargarpedidotrazacc, fila.idprecargarpedido, fila.atlote, fila.pptborrado, fila.atserie, fila.atvencimiento);
    END IF;
    RETURN fila;
    END;
    $function$
