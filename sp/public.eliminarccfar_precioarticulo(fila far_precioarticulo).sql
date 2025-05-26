CREATE OR REPLACE FUNCTION public.eliminarccfar_precioarticulo(fila far_precioarticulo)
 RETURNS far_precioarticulo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precioarticulocc:= current_timestamp;
    delete from sincro.far_precioarticulo WHERE idcentroprecioarticulo= fila.idcentroprecioarticulo AND idprecioarticulo= fila.idprecioarticulo AND TRUE;
    RETURN fila;
    END;
    $function$
