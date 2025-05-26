CREATE OR REPLACE FUNCTION public.insertarccfar_movimientostockitem(fila far_movimientostockitem)
 RETURNS far_movimientostockitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemcc:= current_timestamp;
    UPDATE sincro.far_movimientostockitem SET far_movimientostockitemcc= fila.far_movimientostockitemcc, idcentrolote= fila.idcentrolote, idcentromovimientostock= fila.idcentromovimientostock, idcentromovimientostockitem= fila.idcentromovimientostockitem, idlote= fila.idlote, idmovimientostock= fila.idmovimientostock, idmovimientostockitem= fila.idmovimientostockitem, mscantidad= fila.mscantidad, msisigno= fila.msisigno, msistockanterior= fila.msistockanterior, msistockposterior= fila.msistockposterior WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND idmovimientostockitem= fila.idmovimientostockitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_movimientostockitem(far_movimientostockitemcc, idcentrolote, idcentromovimientostock, idcentromovimientostockitem, idlote, idmovimientostock, idmovimientostockitem, mscantidad, msisigno, msistockanterior, msistockposterior) VALUES (fila.far_movimientostockitemcc, fila.idcentrolote, fila.idcentromovimientostock, fila.idcentromovimientostockitem, fila.idlote, fila.idmovimientostock, fila.idmovimientostockitem, fila.mscantidad, fila.msisigno, fila.msistockanterior, fila.msistockposterior);
    END IF;
    RETURN fila;
    END;
    $function$
