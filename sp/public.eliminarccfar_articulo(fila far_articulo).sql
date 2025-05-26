CREATE OR REPLACE FUNCTION public.eliminarccfar_articulo(fila far_articulo)
 RETURNS far_articulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulocc:= current_timestamp;
    delete from sincro.far_articulo WHERE idarticulo= fila.idarticulo AND idcentroarticulo= fila.idcentroarticulo AND TRUE;
    RETURN fila;
    END;
    $function$
