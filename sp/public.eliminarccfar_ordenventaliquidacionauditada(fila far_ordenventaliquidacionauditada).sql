CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaliquidacionauditada(fila far_ordenventaliquidacionauditada)
 RETURNS far_ordenventaliquidacionauditada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaliquidacionauditadacc:= current_timestamp;
    delete from sincro.far_ordenventaliquidacionauditada WHERE anio= fila.anio AND idcentroliquidacion= fila.idcentroliquidacion AND idcentroordenventaitem= fila.idcentroordenventaitem AND idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte AND idliquidacion= fila.idliquidacion AND idordenventaitem= fila.idordenventaitem AND idordenventaitemimporte= fila.idordenventaitemimporte AND nroregistro= fila.nroregistro AND TRUE;
    RETURN fila;
    END;
    $function$
