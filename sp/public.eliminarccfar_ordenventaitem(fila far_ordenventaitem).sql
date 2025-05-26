CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaitem(fila far_ordenventaitem)
 RETURNS far_ordenventaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemcc:= current_timestamp;
    delete from sincro.far_ordenventaitem WHERE idcentroordenventaitem= fila.idcentroordenventaitem AND idordenventaitem= fila.idordenventaitem AND TRUE;
    RETURN fila;
    END;
    $function$
