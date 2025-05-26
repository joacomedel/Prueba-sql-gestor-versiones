CREATE OR REPLACE FUNCTION public.eliminarccfichamedicainfo(fila fichamedicainfo)
 RETURNS fichamedicainfo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicainfocc:= current_timestamp;
    delete from sincro.fichamedicainfo WHERE idfichamedicainfo= fila.idfichamedicainfo AND idcentrofichamedicainfo= fila.idcentrofichamedicainfo AND TRUE;
    RETURN fila;
    END;
    $function$
