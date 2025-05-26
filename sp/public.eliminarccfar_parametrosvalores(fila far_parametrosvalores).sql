CREATE OR REPLACE FUNCTION public.eliminarccfar_parametrosvalores(fila far_parametrosvalores)
 RETURNS far_parametrosvalores
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_parametrosvalorescc:= current_timestamp;
    delete from sincro.far_parametrosvalores WHERE idcentroregional= fila.idcentroregional AND idparametro= fila.idparametro AND TRUE;
    RETURN fila;
    END;
    $function$
