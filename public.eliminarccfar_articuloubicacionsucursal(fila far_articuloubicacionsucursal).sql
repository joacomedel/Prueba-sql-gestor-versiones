CREATE OR REPLACE FUNCTION public.eliminarccfar_articuloubicacionsucursal(fila far_articuloubicacionsucursal)
 RETURNS far_articuloubicacionsucursal
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articuloubicacionsucursalcc:= current_timestamp;
    delete from sincro.far_articuloubicacionsucursal WHERE idarticuloubicacionsucursal= fila.idarticuloubicacionsucursal AND idcentroarticuloubicacionsucursal= fila.idcentroarticuloubicacionsucursal AND TRUE;
    RETURN fila;
    END;
    $function$
