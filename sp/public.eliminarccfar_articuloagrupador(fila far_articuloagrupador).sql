CREATE OR REPLACE FUNCTION public.eliminarccfar_articuloagrupador(fila far_articuloagrupador)
 RETURNS far_articuloagrupador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articuloagrupadorcc:= current_timestamp;
    delete from sincro.far_articuloagrupador WHERE idarticuloagrupador= fila.idarticuloagrupador AND idcentroarticuloagrupador= fila.idcentroarticuloagrupador AND TRUE;
    RETURN fila;
    END;
    $function$
