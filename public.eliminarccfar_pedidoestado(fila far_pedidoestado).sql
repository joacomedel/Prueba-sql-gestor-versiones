CREATE OR REPLACE FUNCTION public.eliminarccfar_pedidoestado(fila far_pedidoestado)
 RETURNS far_pedidoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_pedidoestadocc:= current_timestamp;
    delete from sincro.far_pedidoestado WHERE idpedidoestado= fila.idpedidoestado AND idcentropedidoestado= fila.idcentropedidoestado AND TRUE;
    RETURN fila;
    END;
    $function$
