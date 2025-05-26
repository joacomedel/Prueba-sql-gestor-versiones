CREATE OR REPLACE FUNCTION public.insertarccfar_articuloubicacionsucursal(fila far_articuloubicacionsucursal)
 RETURNS far_articuloubicacionsucursal
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articuloubicacionsucursalcc:= current_timestamp;
    UPDATE sincro.far_articuloubicacionsucursal SET idubicacionsucursal= fila.idubicacionsucursal, idcentroarticulo= fila.idcentroarticulo, idarticulo= fila.idarticulo, far_articuloubicacionsucursalcc= fila.far_articuloubicacionsucursalcc, ausfechaini= fila.ausfechaini, idarticuloubicacionsucursal= fila.idarticuloubicacionsucursal, idcentroarticuloubicacionsucursal= fila.idcentroarticuloubicacionsucursal, idcentroubicacionsucursal= fila.idcentroubicacionsucursal, ausfechafin= fila.ausfechafin WHERE idarticuloubicacionsucursal= fila.idarticuloubicacionsucursal AND idcentroarticuloubicacionsucursal= fila.idcentroarticuloubicacionsucursal AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_articuloubicacionsucursal(idubicacionsucursal, idcentroarticulo, idarticulo, far_articuloubicacionsucursalcc, ausfechaini, idarticuloubicacionsucursal, idcentroarticuloubicacionsucursal, idcentroubicacionsucursal, ausfechafin) VALUES (fila.idubicacionsucursal, fila.idcentroarticulo, fila.idarticulo, fila.far_articuloubicacionsucursalcc, fila.ausfechaini, fila.idarticuloubicacionsucursal, fila.idcentroarticuloubicacionsucursal, fila.idcentroubicacionsucursal, fila.ausfechafin);
    END IF;
    RETURN fila;
    END;
    $function$
