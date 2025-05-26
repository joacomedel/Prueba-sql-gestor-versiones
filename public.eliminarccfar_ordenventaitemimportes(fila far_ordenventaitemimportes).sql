CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaitemimportes(fila far_ordenventaitemimportes)
 RETURNS far_ordenventaitemimportes
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemimportescc:= current_timestamp;
    delete from sincro.far_ordenventaitemimportes WHERE idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte AND idordenventaitemimporte= fila.idordenventaitemimporte AND TRUE;
    RETURN fila;
    END;
    $function$
