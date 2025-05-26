CREATE OR REPLACE FUNCTION public.eliminarccfar_movimientostockitemordenventa(fila far_movimientostockitemordenventa)
 RETURNS far_movimientostockitemordenventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemordenventacc:= current_timestamp;
    delete from sincro.far_movimientostockitemordenventa WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND idcentroordenventaitem= fila.idcentroordenventaitem AND idmovimientostockitem= fila.idmovimientostockitem AND idordenventaitem= fila.idordenventaitem AND TRUE;
    RETURN fila;
    END;
    $function$
