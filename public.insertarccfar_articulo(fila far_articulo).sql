CREATE OR REPLACE FUNCTION public.insertarccfar_articulo(fila far_articulo)
 RETURNS far_articulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulocc:= current_timestamp;
    UPDATE sincro.far_articulo SET idrubro= fila.idrubro, acomentario= fila.acomentario, astockmax= fila.astockmax, afactorcorreccion= fila.afactorcorreccion, actacble= fila.actacble, idcentroarticulopadre= fila.idcentroarticulopadre, adescripcion= fila.adescripcion, idiva= fila.idiva, idarticulopadre= fila.idarticulopadre, idcentroarticulo= fila.idcentroarticulo, aactivo= fila.aactivo, idarticulo= fila.idarticulo, astockmin= fila.astockmin, acodigointerno= fila.acodigointerno, afraccion= fila.afraccion, acodigobarra= fila.acodigobarra, far_articulocc= fila.far_articulocc, adescuento= fila.adescuento, apreciokairos= fila.apreciokairos WHERE idarticulo= fila.idarticulo AND idcentroarticulo= fila.idcentroarticulo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_articulo(idrubro, acomentario, astockmax, afactorcorreccion, actacble, idcentroarticulopadre, adescripcion, idiva, idarticulopadre, idcentroarticulo, aactivo, idarticulo, astockmin, acodigointerno, afraccion, acodigobarra, far_articulocc, adescuento, apreciokairos) VALUES (fila.idrubro, fila.acomentario, fila.astockmax, fila.afactorcorreccion, fila.actacble, fila.idcentroarticulopadre, fila.adescripcion, fila.idiva, fila.idarticulopadre, fila.idcentroarticulo, fila.aactivo, fila.idarticulo, fila.astockmin, fila.acodigointerno, fila.afraccion, fila.acodigobarra, fila.far_articulocc, fila.adescuento, fila.apreciokairos);
    END IF;
    RETURN fila;
    END;
    $function$
