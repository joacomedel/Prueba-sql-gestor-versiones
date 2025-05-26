CREATE OR REPLACE FUNCTION public.eliminarccfar_pedido(fila far_pedido)
 RETURNS far_pedido
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_pedidocc:= current_timestamp;
    delete from sincro.far_pedido WHERE idcentropedido= fila.idcentropedido AND idpedido= fila.idpedido AND TRUE;
    RETURN fila;
    END;
    $function$
