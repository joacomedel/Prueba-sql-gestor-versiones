CREATE OR REPLACE FUNCTION public.eliminarccfar_precioarticulosugerido(fila far_precioarticulosugerido)
 RETURNS far_precioarticulosugerido
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precioarticulosugeridocc:= current_timestamp;
    delete from sincro.far_precioarticulosugerido WHERE idcentroprecioarticulosuerido= fila.idcentroprecioarticulosuerido AND idprecioarticulosugerido= fila.idprecioarticulosugerido AND TRUE;
    RETURN fila;
    END;
    $function$
