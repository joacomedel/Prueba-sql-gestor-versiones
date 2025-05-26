CREATE OR REPLACE FUNCTION public.eliminarccfar_precargarpedidotraza(fila far_precargarpedidotraza)
 RETURNS far_precargarpedidotraza
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidotrazacc:= current_timestamp;
    delete from sincro.far_precargarpedidotraza WHERE idprecargarpedidotraza= fila.idprecargarpedidotraza AND idcentroprecargarpedidotraza= fila.idcentroprecargarpedidotraza AND TRUE;
    RETURN fila;
    END;
    $function$
