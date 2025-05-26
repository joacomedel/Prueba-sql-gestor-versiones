CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaestado(fila far_ordenventaestado)
 RETURNS far_ordenventaestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaestadocc:= current_timestamp;
    delete from sincro.far_ordenventaestado WHERE idordenventaestado= fila.idordenventaestado AND idcentroordenventaestado= fila.idcentroordenventaestado AND TRUE;
    RETURN fila;
    END;
    $function$
