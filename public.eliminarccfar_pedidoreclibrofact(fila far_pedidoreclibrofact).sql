CREATE OR REPLACE FUNCTION public.eliminarccfar_pedidoreclibrofact(fila far_pedidoreclibrofact)
 RETURNS far_pedidoreclibrofact
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_pedidoreclibrofactcc:= current_timestamp;
    delete from sincro.far_pedidoreclibrofact WHERE anio= fila.anio AND idcentropedido= fila.idcentropedido AND idpedido= fila.idpedido AND numeroregistro= fila.numeroregistro AND TRUE;
    RETURN fila;
    END;
    $function$
