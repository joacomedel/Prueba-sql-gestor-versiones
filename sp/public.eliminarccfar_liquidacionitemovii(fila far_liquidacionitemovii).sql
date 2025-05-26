CREATE OR REPLACE FUNCTION public.eliminarccfar_liquidacionitemovii(fila far_liquidacionitemovii)
 RETURNS far_liquidacionitemovii
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionitemoviicc:= current_timestamp;
    delete from sincro.far_liquidacionitemovii WHERE idcentroliquidacionitem= fila.idcentroliquidacionitem AND idcentroordenventaitem= fila.idcentroordenventaitem AND idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte AND idliquidacionitem= fila.idliquidacionitem AND idordenventaitem= fila.idordenventaitem AND idordenventaitemimporte= fila.idordenventaitemimporte AND TRUE;
    RETURN fila;
    END;
    $function$
