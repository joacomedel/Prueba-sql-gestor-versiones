CREATE OR REPLACE FUNCTION public.eliminarccfichamedicaemision(fila fichamedicaemision)
 RETURNS fichamedicaemision
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaemisioncc:= current_timestamp;
    delete from sincro.fichamedicaemision WHERE idauditoriatipo= fila.idauditoriatipo AND idfichamedicaitem= fila.idfichamedicaitem AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND TRUE;
    RETURN fila;
    END;
    $function$
