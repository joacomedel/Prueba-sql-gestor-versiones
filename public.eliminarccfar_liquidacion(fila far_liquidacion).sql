CREATE OR REPLACE FUNCTION public.eliminarccfar_liquidacion(fila far_liquidacion)
 RETURNS far_liquidacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacioncc:= current_timestamp;
    delete from sincro.far_liquidacion WHERE idliquidacion= fila.idliquidacion AND idcentroliquidacion= fila.idcentroliquidacion AND TRUE;
    RETURN fila;
    END;
    $function$
