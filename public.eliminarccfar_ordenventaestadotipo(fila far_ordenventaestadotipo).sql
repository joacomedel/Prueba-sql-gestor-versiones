CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaestadotipo(fila far_ordenventaestadotipo)
 RETURNS far_ordenventaestadotipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaestadotipocc:= current_timestamp;
    delete from sincro.far_ordenventaestadotipo WHERE idordenventaestadotipo= fila.idordenventaestadotipo AND TRUE;
    RETURN fila;
    END;
    $function$
