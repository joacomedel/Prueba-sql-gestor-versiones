CREATE OR REPLACE FUNCTION public.insertarccfar_archivotrazabilidadarticulo(fila far_archivotrazabilidadarticulo)
 RETURNS far_archivotrazabilidadarticulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_archivotrazabilidadarticulocc:= current_timestamp;
    UPDATE sincro.far_archivotrazabilidadarticulo SET idcentroarchivostrazabilidad= fila.idcentroarchivostrazabilidad, atalinea= fila.atalinea, idarticulotraza= fila.idarticulotraza, idcentroarticulotraza= fila.idcentroarticulotraza, idarchivostrazabilidad= fila.idarchivostrazabilidad, far_archivotrazabilidadarticulocc= fila.far_archivotrazabilidadarticulocc WHERE idcentroarchivostrazabilidad= fila.idcentroarchivostrazabilidad AND idarchivostrazabilidad= fila.idarchivostrazabilidad AND idarticulotraza= fila.idarticulotraza AND idcentroarticulotraza= fila.idcentroarticulotraza AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_archivotrazabilidadarticulo(idcentroarchivostrazabilidad, atalinea, idarticulotraza, idcentroarticulotraza, idarchivostrazabilidad, far_archivotrazabilidadarticulocc) VALUES (fila.idcentroarchivostrazabilidad, fila.atalinea, fila.idarticulotraza, fila.idcentroarticulotraza, fila.idarchivostrazabilidad, fila.far_archivotrazabilidadarticulocc);
    END IF;
    RETURN fila;
    END;
    $function$
