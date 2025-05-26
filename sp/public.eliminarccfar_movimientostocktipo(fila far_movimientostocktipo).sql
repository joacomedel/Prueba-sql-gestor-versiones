CREATE OR REPLACE FUNCTION public.eliminarccfar_movimientostocktipo(fila far_movimientostocktipo)
 RETURNS far_movimientostocktipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostocktipocc:= current_timestamp;
    delete from sincro.far_movimientostocktipo WHERE idmovimientostocktipo= fila.idmovimientostocktipo AND TRUE;
    RETURN fila;
    END;
    $function$
