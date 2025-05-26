CREATE OR REPLACE FUNCTION public.insertarccfar_movimientostock(fila far_movimientostock)
 RETURNS far_movimientostock
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockcc:= current_timestamp;
    UPDATE sincro.far_movimientostock SET far_movimientostockcc= fila.far_movimientostockcc, idcentromovimientostock= fila.idcentromovimientostock, idmovimientostock= fila.idmovimientostock, idmovimientostocktipo= fila.idmovimientostocktipo, msdescripcion= fila.msdescripcion, msfecha= fila.msfecha, msidcomprobante= fila.msidcomprobante, msnombretabla= fila.msnombretabla WHERE idmovimientostock= fila.idmovimientostock AND idcentromovimientostock= fila.idcentromovimientostock AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_movimientostock(far_movimientostockcc, idcentromovimientostock, idmovimientostock, idmovimientostocktipo, msdescripcion, msfecha, msidcomprobante, msnombretabla) VALUES (fila.far_movimientostockcc, fila.idcentromovimientostock, fila.idmovimientostock, fila.idmovimientostocktipo, fila.msdescripcion, fila.msfecha, fila.msidcomprobante, fila.msnombretabla);
    END IF;
    RETURN fila;
    END;
    $function$
