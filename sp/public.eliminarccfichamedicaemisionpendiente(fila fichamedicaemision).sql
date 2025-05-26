CREATE OR REPLACE FUNCTION public.eliminarccfichamedicaemisionpendiente(fila fichamedicaemision)
 RETURNS fichamedicaemision
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaemisionpendientecc:= current_timestamp;
    delete from sincro.fichamedicaemisionpendiente WHERE idauditoriatipo= fila.idauditoriatipo AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND idfichamedicaitem= fila.idfichamedicaitem AND TRUE;
    RETURN fila;
    END;
    $function$
