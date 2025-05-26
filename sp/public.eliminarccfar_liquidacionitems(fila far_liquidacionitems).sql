CREATE OR REPLACE FUNCTION public.eliminarccfar_liquidacionitems(fila far_liquidacionitems)
 RETURNS far_liquidacionitems
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionitemscc:= current_timestamp;
    delete from sincro.far_liquidacionitems WHERE idcentroliquidacionitem= fila.idcentroliquidacionitem AND idliquidacionitem= fila.idliquidacionitem AND TRUE;
    RETURN fila;
    END;
    $function$
