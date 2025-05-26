CREATE OR REPLACE FUNCTION public.eliminarccfar_liquidacionestado(fila far_liquidacionestado)
 RETURNS far_liquidacionestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionestadocc:= current_timestamp;
    delete from sincro.far_liquidacionestado WHERE idcentroliquidacionestado= fila.idcentroliquidacionestado AND idliquidacionestado= fila.idliquidacionestado AND TRUE;
    RETURN fila;
    END;
    $function$
