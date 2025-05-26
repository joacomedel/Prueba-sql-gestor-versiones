CREATE OR REPLACE FUNCTION public.eliminarccfar_movimientostock(fila far_movimientostock)
 RETURNS far_movimientostock
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockcc:= current_timestamp;
    delete from sincro.far_movimientostock WHERE idmovimientostock= fila.idmovimientostock AND idcentromovimientostock= fila.idcentromovimientostock AND TRUE;
    RETURN fila;
    END;
    $function$
