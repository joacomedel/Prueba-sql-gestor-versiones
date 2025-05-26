CREATE OR REPLACE FUNCTION public.insertarccfar_movimientostocktipo(fila far_movimientostocktipo)
 RETURNS far_movimientostocktipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostocktipocc:= current_timestamp;
    UPDATE sincro.far_movimientostocktipo SET far_movimientostocktipocc= fila.far_movimientostocktipocc, idmovimientostocktipo= fila.idmovimientostocktipo, tmsdescripcion= fila.tmsdescripcion WHERE idmovimientostocktipo= fila.idmovimientostocktipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_movimientostocktipo(far_movimientostocktipocc, idmovimientostocktipo, tmsdescripcion) VALUES (fila.far_movimientostocktipocc, fila.idmovimientostocktipo, fila.tmsdescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
