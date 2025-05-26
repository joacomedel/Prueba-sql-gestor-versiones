CREATE OR REPLACE FUNCTION public.eliminarccfichamedicaitemsico(fila fichamedicaitemsico)
 RETURNS fichamedicaitemsico
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitemsicocc:= current_timestamp;
    delete from sincro.fichamedicaitemsico WHERE idcentrofichamedicaitemsico= fila.idcentrofichamedicaitemsico AND idfichamedicaitemsico= fila.idfichamedicaitemsico AND TRUE;
    RETURN fila;
    END;
    $function$
