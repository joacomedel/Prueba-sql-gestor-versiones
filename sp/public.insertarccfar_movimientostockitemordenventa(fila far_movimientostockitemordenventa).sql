CREATE OR REPLACE FUNCTION public.insertarccfar_movimientostockitemordenventa(fila far_movimientostockitemordenventa)
 RETURNS far_movimientostockitemordenventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemordenventacc:= current_timestamp;
    UPDATE sincro.far_movimientostockitemordenventa SET far_movimientostockitemordenventacc= fila.far_movimientostockitemordenventacc, idcentromovimientostockitem= fila.idcentromovimientostockitem, idcentroordenventaitem= fila.idcentroordenventaitem, idmovimientostockitem= fila.idmovimientostockitem, idordenventaitem= fila.idordenventaitem, msiovsigno= fila.msiovsigno WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND idcentroordenventaitem= fila.idcentroordenventaitem AND idmovimientostockitem= fila.idmovimientostockitem AND idordenventaitem= fila.idordenventaitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_movimientostockitemordenventa(far_movimientostockitemordenventacc, idcentromovimientostockitem, idcentroordenventaitem, idmovimientostockitem, idordenventaitem, msiovsigno) VALUES (fila.far_movimientostockitemordenventacc, fila.idcentromovimientostockitem, fila.idcentroordenventaitem, fila.idmovimientostockitem, fila.idordenventaitem, fila.msiovsigno);
    END IF;
    RETURN fila;
    END;
    $function$
