CREATE OR REPLACE FUNCTION public.insertarccfar_movimientostockitemremito(fila far_movimientostockitemremito)
 RETURNS far_movimientostockitemremito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemremitocc:= current_timestamp;
    UPDATE sincro.far_movimientostockitemremito SET far_movimientostockitemremitocc= fila.far_movimientostockitemremitocc, idcentromovimientostockitem= fila.idcentromovimientostockitem, idcentroremitoitem= fila.idcentroremitoitem, idmovimientostockitem= fila.idmovimientostockitem, idremitoitem= fila.idremitoitem WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND idmovimientostockitem= fila.idmovimientostockitem AND idremitoitem= fila.idremitoitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_movimientostockitemremito(far_movimientostockitemremitocc, idcentromovimientostockitem, idcentroremitoitem, idmovimientostockitem, idremitoitem) VALUES (fila.far_movimientostockitemremitocc, fila.idcentromovimientostockitem, fila.idcentroremitoitem, fila.idmovimientostockitem, fila.idremitoitem);
    END IF;
    RETURN fila;
    END;
    $function$
