CREATE OR REPLACE FUNCTION public.eliminarccfichamedicapreauditadaodonto(fila fichamedicapreauditadaodonto)
 RETURNS fichamedicapreauditadaodonto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadaodontocc:= current_timestamp;
    delete from sincro.fichamedicapreauditadaodonto WHERE idcentrofichamedicapreauditadaodonto= fila.idcentrofichamedicapreauditadaodonto AND idfichamedicapreauditadaodonto= fila.idfichamedicapreauditadaodonto AND TRUE;
    RETURN fila;
    END;
    $function$
