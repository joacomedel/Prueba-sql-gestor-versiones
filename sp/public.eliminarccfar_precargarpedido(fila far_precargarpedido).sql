CREATE OR REPLACE FUNCTION public.eliminarccfar_precargarpedido(fila far_precargarpedido)
 RETURNS far_precargarpedido
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidocc:= current_timestamp;
    delete from sincro.far_precargarpedido WHERE idprecargarpedido= fila.idprecargarpedido AND idcentroprecargapedido= fila.idcentroprecargapedido AND TRUE;
    RETURN fila;
    END;
    $function$
