CREATE OR REPLACE FUNCTION public.eliminarccfar_movimientostockitem(fila far_movimientostockitem)
 RETURNS far_movimientostockitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemcc:= current_timestamp;
    delete from sincro.far_movimientostockitem WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND idmovimientostockitem= fila.idmovimientostockitem AND TRUE;
    RETURN fila;
    END;
    $function$
