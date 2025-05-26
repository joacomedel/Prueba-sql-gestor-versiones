CREATE OR REPLACE FUNCTION public.eliminarccfar_liquidacionitemestado(fila far_liquidacionitemestado)
 RETURNS far_liquidacionitemestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionitemestadocc:= current_timestamp;
    delete from sincro.far_liquidacionitemestado WHERE idliquidacionitemestado= fila.idliquidacionitemestado AND idestadotipo= fila.idestadotipo AND idcentroliquidacionitem= fila.idcentroliquidacionitem AND idliquidacionitem= fila.idliquidacionitem AND TRUE;
    RETURN fila;
    END;
    $function$
