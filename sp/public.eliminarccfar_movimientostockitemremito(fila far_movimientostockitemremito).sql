CREATE OR REPLACE FUNCTION public.eliminarccfar_movimientostockitemremito(fila far_movimientostockitemremito)
 RETURNS far_movimientostockitemremito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemremitocc:= current_timestamp;
    delete from sincro.far_movimientostockitemremito WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND idmovimientostockitem= fila.idmovimientostockitem AND idremitoitem= fila.idremitoitem AND TRUE;
    RETURN fila;
    END;
    $function$
