CREATE OR REPLACE FUNCTION public.eliminarccfar_rubro(fila far_rubro)
 RETURNS far_rubro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_rubrocc:= current_timestamp;
    delete from sincro.far_rubro WHERE idrubro= fila.idrubro AND TRUE;
    RETURN fila;
    END;
    $function$
