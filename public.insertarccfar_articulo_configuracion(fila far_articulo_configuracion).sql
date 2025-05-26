CREATE OR REPLACE FUNCTION public.insertarccfar_articulo_configuracion(fila far_articulo_configuracion)
 RETURNS far_articulo_configuracion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulo_configuracioncc:= current_timestamp;
    UPDATE sincro.far_articulo_configuracion SET accantidadimpresiones= fila.accantidadimpresiones, acidusuarioimprimio= fila.acidusuarioimprimio, acrequiereimprimir= fila.acrequiereimprimir, acseimprimieron= fila.acseimprimieron, far_articulo_configuracioncc= fila.far_articulo_configuracioncc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo WHERE idarticulo= fila.idarticulo AND idcentroarticulo= fila.idcentroarticulo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_articulo_configuracion(accantidadimpresiones, acidusuarioimprimio, acrequiereimprimir, acseimprimieron, far_articulo_configuracioncc, idarticulo, idcentroarticulo) VALUES (fila.accantidadimpresiones, fila.acidusuarioimprimio, fila.acrequiereimprimir, fila.acseimprimieron, fila.far_articulo_configuracioncc, fila.idarticulo, fila.idcentroarticulo);
    END IF;
    RETURN fila;
    END;
    $function$
