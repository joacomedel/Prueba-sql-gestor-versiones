CREATE OR REPLACE FUNCTION public.eliminarccfar_articulotrazabilidad(fila far_articulotrazabilidad)
 RETURNS far_articulotrazabilidad
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulotrazabilidadcc:= current_timestamp;
    delete from sincro.far_articulotrazabilidad WHERE idarticulotraza= fila.idarticulotraza AND idcentroarticulotraza= fila.idcentroarticulotraza AND TRUE;
    RETURN fila;
    END;
    $function$
