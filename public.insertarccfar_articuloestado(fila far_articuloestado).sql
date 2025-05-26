CREATE OR REPLACE FUNCTION public.insertarccfar_articuloestado(fila far_articuloestado)
 RETURNS far_articuloestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articuloestadocc:= current_timestamp;
    UPDATE sincro.far_articuloestado SET aedescripcion= fila.aedescripcion, aefechafin= fila.aefechafin, aefechaini= fila.aefechaini, aeidusuario= fila.aeidusuario, far_articuloestadocc= fila.far_articuloestadocc, idarticulo= fila.idarticulo, idarticuloestado= fila.idarticuloestado, idarticuloestadotipo= fila.idarticuloestadotipo, idcentroarticulo= fila.idcentroarticulo, idcentroarticuloestado= fila.idcentroarticuloestado WHERE idarticuloestado= fila.idarticuloestado AND idcentroarticuloestado= fila.idcentroarticuloestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_articuloestado(aedescripcion, aefechafin, aefechaini, aeidusuario, far_articuloestadocc, idarticulo, idarticuloestado, idarticuloestadotipo, idcentroarticulo, idcentroarticuloestado) VALUES (fila.aedescripcion, fila.aefechafin, fila.aefechaini, fila.aeidusuario, fila.far_articuloestadocc, fila.idarticulo, fila.idarticuloestado, fila.idarticuloestadotipo, fila.idcentroarticulo, fila.idcentroarticuloestado);
    END IF;
    RETURN fila;
    END;
    $function$
