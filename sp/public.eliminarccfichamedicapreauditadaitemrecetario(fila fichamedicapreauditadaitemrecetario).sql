CREATE OR REPLACE FUNCTION public.eliminarccfichamedicapreauditadaitemrecetario(fila fichamedicapreauditadaitemrecetario)
 RETURNS fichamedicapreauditadaitemrecetario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadaitemrecetariocc:= current_timestamp;
    delete from sincro.fichamedicapreauditadaitemrecetario WHERE idrecetarioitem= fila.idrecetarioitem AND idcentrorecetarioitem= fila.idcentrorecetarioitem AND idfichamedicapreauditada= fila.idfichamedicapreauditada AND idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada AND TRUE;
    RETURN fila;
    END;
    $function$
