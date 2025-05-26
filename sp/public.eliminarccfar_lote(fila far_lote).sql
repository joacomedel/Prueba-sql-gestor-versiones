CREATE OR REPLACE FUNCTION public.eliminarccfar_lote(fila far_lote)
 RETURNS far_lote
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_lotecc:= current_timestamp;
    delete from sincro.far_lote WHERE idcentrolote= fila.idcentrolote AND idlote= fila.idlote AND TRUE;
    RETURN fila;
    END;
    $function$
