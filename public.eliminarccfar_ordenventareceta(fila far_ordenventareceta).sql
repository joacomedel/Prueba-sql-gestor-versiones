CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventareceta(fila far_ordenventareceta)
 RETURNS far_ordenventareceta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventarecetacc:= current_timestamp;
    delete from sincro.far_ordenventareceta WHERE idcentroordenventaprofesion= fila.idcentroordenventaprofesion AND idordenventaprofesional= fila.idordenventaprofesional AND TRUE;
    RETURN fila;
    END;
    $function$
