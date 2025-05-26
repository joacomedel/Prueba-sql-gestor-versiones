CREATE OR REPLACE FUNCTION public.eliminarccfichamedicaitememisiones(fila fichamedicaitememisiones)
 RETURNS fichamedicaitememisiones
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitememisionescc:= current_timestamp;
    delete from sincro.fichamedicaitememisiones WHERE idcentrofichamedicaitememisiones= fila.idcentrofichamedicaitememisiones AND idfichamedicaitememisiones= fila.idfichamedicaitememisiones AND TRUE;
    RETURN fila;
    END;
    $function$
