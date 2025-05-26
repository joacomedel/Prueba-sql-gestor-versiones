CREATE OR REPLACE FUNCTION public.eliminarccfar_pedidoitems(fila far_pedidoitems)
 RETURNS far_pedidoitems
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_pedidoitemscc:= current_timestamp;
    delete from sincro.far_pedidoitems WHERE idpedidoitem= fila.idpedidoitem AND idcentropedidoitem= fila.idcentropedidoitem AND TRUE;
    RETURN fila;
    END;
    $function$
