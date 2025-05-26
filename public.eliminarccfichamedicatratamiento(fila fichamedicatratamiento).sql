CREATE OR REPLACE FUNCTION public.eliminarccfichamedicatratamiento(fila fichamedicatratamiento)
 RETURNS fichamedicatratamiento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicatratamientocc:= current_timestamp;
    delete from sincro.fichamedicatratamiento WHERE idcentrofichamedicatratamiento= fila.idcentrofichamedicatratamiento AND idfichamedicatratamiento= fila.idfichamedicatratamiento AND TRUE;
    RETURN fila;
    END;
    $function$
