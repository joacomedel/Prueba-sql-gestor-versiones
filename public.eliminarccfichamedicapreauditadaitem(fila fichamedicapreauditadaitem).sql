CREATE OR REPLACE FUNCTION public.eliminarccfichamedicapreauditadaitem(fila fichamedicapreauditadaitem)
 RETURNS fichamedicapreauditadaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadaitemcc:= current_timestamp;
    delete from sincro.fichamedicapreauditadaitem WHERE centro= fila.centro AND idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada AND idfichamedicapreauditada= fila.idfichamedicapreauditada AND iditem= fila.iditem AND TRUE;
    RETURN fila;
    END;
    $function$
