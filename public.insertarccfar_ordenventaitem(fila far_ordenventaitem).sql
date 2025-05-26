CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaitem(fila far_ordenventaitem)
 RETURNS far_ordenventaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemcc:= current_timestamp;
    UPDATE sincro.far_ordenventaitem SET far_ordenventaitemcc= fila.far_ordenventaitemcc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentroordenventa= fila.idcentroordenventa, idcentroordenventaitem= fila.idcentroordenventaitem, idordenventa= fila.idordenventa, idordenventaitem= fila.idordenventaitem, ovicantidad= fila.ovicantidad, ovidescripcion= fila.ovidescripcion, ovidescuento= fila.ovidescuento, oviidiva= fila.oviidiva, oviimpdescuento= fila.oviimpdescuento, oviimporteiva= fila.oviimporteiva, ovipreciolista= fila.ovipreciolista, oviprecioventa= fila.oviprecioventa WHERE idcentroordenventaitem= fila.idcentroordenventaitem AND idordenventaitem= fila.idordenventaitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaitem(far_ordenventaitemcc, idarticulo, idcentroarticulo, idcentroordenventa, idcentroordenventaitem, idordenventa, idordenventaitem, ovicantidad, ovidescripcion, ovidescuento, oviidiva, oviimpdescuento, oviimporteiva, ovipreciolista, oviprecioventa) VALUES (fila.far_ordenventaitemcc, fila.idarticulo, fila.idcentroarticulo, fila.idcentroordenventa, fila.idcentroordenventaitem, fila.idordenventa, fila.idordenventaitem, fila.ovicantidad, fila.ovidescripcion, fila.ovidescuento, fila.oviidiva, fila.oviimpdescuento, fila.oviimporteiva, fila.ovipreciolista, fila.oviprecioventa);
    END IF;
    RETURN fila;
    END;
    $function$
