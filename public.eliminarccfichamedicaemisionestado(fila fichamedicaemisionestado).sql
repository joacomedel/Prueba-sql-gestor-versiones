CREATE OR REPLACE FUNCTION public.eliminarccfichamedicaemisionestado(fila fichamedicaemisionestado)
 RETURNS fichamedicaemisionestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaemisionestadocc:= current_timestamp;
    delete from sincro.fichamedicaemisionestado WHERE idcentrofichamedicaemisionestado= fila.idcentrofichamedicaemisionestado AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND idfichamedicaemisionestado= fila.idfichamedicaemisionestado AND idfichamedicaitem= fila.idfichamedicaitem AND TRUE;
    RETURN fila;
    END;
    $function$
