CREATE OR REPLACE FUNCTION public.eliminarccfichamedicaitempendiente(fila fichamedicaitempendiente)
 RETURNS fichamedicaitempendiente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitempendientecc:= current_timestamp;
    delete from sincro.fichamedicaitempendiente WHERE idcentrofichamedicaitempendiente= fila.idcentrofichamedicaitempendiente AND idfichamedicaitempendiente= fila.idfichamedicaitempendiente AND TRUE;
    RETURN fila;
    END;
    $function$
