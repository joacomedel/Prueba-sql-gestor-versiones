CREATE OR REPLACE FUNCTION public.eliminarccfar_archivotrazabilidadarticulo(fila far_archivotrazabilidadarticulo)
 RETURNS far_archivotrazabilidadarticulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_archivotrazabilidadarticulocc:= current_timestamp;
    delete from sincro.far_archivotrazabilidadarticulo WHERE idcentroarchivostrazabilidad= fila.idcentroarchivostrazabilidad AND idarchivostrazabilidad= fila.idarchivostrazabilidad AND idarticulotraza= fila.idarticulotraza AND idcentroarticulotraza= fila.idcentroarticulotraza AND TRUE;
    RETURN fila;
    END;
    $function$
