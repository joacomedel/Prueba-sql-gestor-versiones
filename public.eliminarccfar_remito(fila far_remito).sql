CREATE OR REPLACE FUNCTION public.eliminarccfar_remito(fila far_remito)
 RETURNS far_remito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitocc:= current_timestamp;
    delete from sincro.far_remito WHERE centro= fila.centro AND idremito= fila.idremito AND TRUE;
    RETURN fila;
    END;
    $function$
