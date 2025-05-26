CREATE OR REPLACE FUNCTION public.insertarccfar_precioarticulo(fila far_precioarticulo)
 RETURNS far_precioarticulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precioarticulocc:= current_timestamp;
    UPDATE sincro.far_precioarticulo SET far_precioarticulocc= fila.far_precioarticulocc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentroprecioarticulo= fila.idcentroprecioarticulo, idprecioarticulo= fila.idprecioarticulo, idusuariocarga= fila.idusuariocarga, pafechafin= fila.pafechafin, pafechaini= fila.pafechaini, pamodificacion= fila.pamodificacion, pavalor= fila.pavalor, pimporteiva= fila.pimporteiva, pvalorcompra= fila.pvalorcompra WHERE idcentroprecioarticulo= fila.idcentroprecioarticulo AND idprecioarticulo= fila.idprecioarticulo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precioarticulo(far_precioarticulocc, idarticulo, idcentroarticulo, idcentroprecioarticulo, idprecioarticulo, idusuariocarga, pafechafin, pafechaini, pamodificacion, pavalor, pimporteiva, pvalorcompra) VALUES (fila.far_precioarticulocc, fila.idarticulo, fila.idcentroarticulo, fila.idcentroprecioarticulo, fila.idprecioarticulo, fila.idusuariocarga, fila.pafechafin, fila.pafechaini, fila.pamodificacion, fila.pavalor, fila.pimporteiva, fila.pvalorcompra);
    END IF;
    RETURN fila;
    END;
    $function$
