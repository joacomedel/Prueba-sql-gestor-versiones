CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaitemvaleregalo(fila far_ordenventaitemvaleregalo)
 RETURNS far_ordenventaitemvaleregalo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemvaleregalocc:= current_timestamp;
    delete from sincro.far_ordenventaitemvaleregalo WHERE idordenventaitemoriginal= fila.idordenventaitemoriginal AND idordenventaitemvaleregalo= fila.idordenventaitemvaleregalo AND idcentroordenventaitemvaleregalo= fila.idcentroordenventaitemvaleregalo AND idcentroordenventaitemoriginal= fila.idcentroordenventaitemoriginal AND TRUE;
    RETURN fila;
    END;
    $function$
