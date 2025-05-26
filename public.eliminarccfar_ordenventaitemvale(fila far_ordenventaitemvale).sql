CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaitemvale(fila far_ordenventaitemvale)
 RETURNS far_ordenventaitemvale
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemvalecc:= current_timestamp;
    delete from sincro.far_ordenventaitemvale WHERE idcentroordenventaitemoriginal= fila.idcentroordenventaitemoriginal AND idcentroordenventaitemvale= fila.idcentroordenventaitemvale AND idordenventaitemoriginal= fila.idordenventaitemoriginal AND idordenventaitemvale= fila.idordenventaitemvale AND TRUE;
    RETURN fila;
    END;
    $function$
