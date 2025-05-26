CREATE OR REPLACE FUNCTION public.insertarccfar_preciocompra(fila far_preciocompra)
 RETURNS far_preciocompra
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_preciocompracc:= current_timestamp;
    UPDATE sincro.far_preciocompra SET far_preciocompracc= fila.far_preciocompracc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentropreciocompra= fila.idcentropreciocompra, idpreciocompra= fila.idpreciocompra, idprestador= fila.idprestador, idusuariocarga= fila.idusuariocarga, pcfechafin= fila.pcfechafin, pcfechafini= fila.pcfechafini, pcprecioventaconivasugerido= fila.pcprecioventaconivasugerido, pcprecioventasinivasugerido= fila.pcprecioventasinivasugerido, preciocompra= fila.preciocompra WHERE idpreciocompra= fila.idpreciocompra AND idcentropreciocompra= fila.idcentropreciocompra AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_preciocompra(far_preciocompracc, idarticulo, idcentroarticulo, idcentropreciocompra, idpreciocompra, idprestador, idusuariocarga, pcfechafin, pcfechafini, pcprecioventaconivasugerido, pcprecioventasinivasugerido, preciocompra) VALUES (fila.far_preciocompracc, fila.idarticulo, fila.idcentroarticulo, fila.idcentropreciocompra, fila.idpreciocompra, fila.idprestador, fila.idusuariocarga, fila.pcfechafin, fila.pcfechafini, fila.pcprecioventaconivasugerido, fila.pcprecioventasinivasugerido, fila.preciocompra);
    END IF;
    RETURN fila;
    END;
    $function$
