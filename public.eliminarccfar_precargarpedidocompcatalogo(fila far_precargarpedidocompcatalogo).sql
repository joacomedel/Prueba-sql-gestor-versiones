CREATE OR REPLACE FUNCTION public.eliminarccfar_precargarpedidocompcatalogo(fila far_precargarpedidocompcatalogo)
 RETURNS far_precargarpedidocompcatalogo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precargarpedidocompcatalogocc:= current_timestamp;
    delete from sincro.far_precargarpedidocompcatalogo WHERE idprecargarpedidocompcatalogo= fila.idprecargarpedidocompcatalogo AND idcentroprecargarpedidocompcatalogo= fila.idcentroprecargarpedidocompcatalogo AND TRUE;
    RETURN fila;
    END;
    $function$
