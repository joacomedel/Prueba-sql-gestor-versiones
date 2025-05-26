CREATE OR REPLACE FUNCTION public.eliminarccfichamedicaitemodonto(fila fichamedicaitemodonto)
 RETURNS fichamedicaitemodonto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitemodontocc:= current_timestamp;
    delete from sincro.fichamedicaitemodonto WHERE idcentrofichamedicaitemodonto= fila.idcentrofichamedicaitemodonto AND idfichamedicaitemodonto= fila.idfichamedicaitemodonto AND TRUE;
    RETURN fila;
    END;
    $function$
