CREATE OR REPLACE FUNCTION public.eliminarccfichamedicapreauditada(fila fichamedicapreauditada)
 RETURNS fichamedicapreauditada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadacc:= current_timestamp;
    delete from sincro.fichamedicapreauditada WHERE idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada AND idfichamedicapreauditada= fila.idfichamedicapreauditada AND TRUE;
    RETURN fila;
    END;
    $function$
