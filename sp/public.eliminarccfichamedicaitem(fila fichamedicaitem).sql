CREATE OR REPLACE FUNCTION public.eliminarccfichamedicaitem(fila fichamedicaitem)
 RETURNS fichamedicaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitemcc:= current_timestamp;
    delete from sincro.fichamedicaitem WHERE idfichamedicaitem= fila.idfichamedicaitem AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND TRUE;
    RETURN fila;
    END;
    $function$
