CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaitemestado(fila far_ordenventaitemestado)
 RETURNS far_ordenventaitemestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemestadocc:= current_timestamp;
    delete from sincro.far_ordenventaitemestado WHERE idcentroordenventaitemestado= fila.idcentroordenventaitemestado AND idordenventaitemaestado= fila.idordenventaitemaestado AND TRUE;
    RETURN fila;
    END;
    $function$
