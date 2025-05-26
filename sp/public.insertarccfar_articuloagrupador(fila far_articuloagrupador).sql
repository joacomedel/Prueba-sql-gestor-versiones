CREATE OR REPLACE FUNCTION public.insertarccfar_articuloagrupador(fila far_articuloagrupador)
 RETURNS far_articuloagrupador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articuloagrupadorcc:= current_timestamp;
    UPDATE sincro.far_articuloagrupador SET aafechafin= fila.aafechafin, idcentroarticulo= fila.idcentroarticulo, far_articuloagrupadorcc= fila.far_articuloagrupadorcc, idcentroarticuloagrupador= fila.idcentroarticuloagrupador, idarticulo= fila.idarticulo, aafechaini= fila.aafechaini, idagrupador= fila.idagrupador, idarticuloagrupador= fila.idarticuloagrupador WHERE idarticuloagrupador= fila.idarticuloagrupador AND idcentroarticuloagrupador= fila.idcentroarticuloagrupador AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_articuloagrupador(aafechafin, idcentroarticulo, far_articuloagrupadorcc, idcentroarticuloagrupador, idarticulo, aafechaini, idagrupador, idarticuloagrupador) VALUES (fila.aafechafin, fila.idcentroarticulo, fila.far_articuloagrupadorcc, fila.idcentroarticuloagrupador, fila.idarticulo, fila.aafechaini, fila.idagrupador, fila.idarticuloagrupador);
    END IF;
    RETURN fila;
    END;
    $function$
