CREATE OR REPLACE FUNCTION public.eliminarccfar_preciocompra(fila far_preciocompra)
 RETURNS far_preciocompra
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_preciocompracc:= current_timestamp;
    delete from sincro.far_preciocompra WHERE idpreciocompra= fila.idpreciocompra AND idcentropreciocompra= fila.idcentropreciocompra AND TRUE;
    RETURN fila;
    END;
    $function$
