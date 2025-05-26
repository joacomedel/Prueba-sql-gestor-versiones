CREATE OR REPLACE FUNCTION public.eliminarccfichamedicapreauditadaitemconsulta(fila fichamedicapreauditadaitemconsulta)
 RETURNS fichamedicapreauditadaitemconsulta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadaitemconsultacc:= current_timestamp;
    delete from sincro.fichamedicapreauditadaitemconsulta WHERE centro= fila.centro AND idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada AND idfichamedicapreauditada= fila.idfichamedicapreauditada AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
