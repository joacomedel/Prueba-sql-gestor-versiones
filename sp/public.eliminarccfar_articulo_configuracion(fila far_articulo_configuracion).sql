CREATE OR REPLACE FUNCTION public.eliminarccfar_articulo_configuracion(fila far_articulo_configuracion)
 RETURNS far_articulo_configuracion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulo_configuracioncc:= current_timestamp;
    delete from sincro.far_articulo_configuracion WHERE idarticulo= fila.idarticulo AND idcentroarticulo= fila.idcentroarticulo AND TRUE;
    RETURN fila;
    END;
    $function$
