CREATE OR REPLACE FUNCTION public.eliminarccfichamedicainfomedrecetarioitem(fila fichamedicainfomedrecetarioitem)
 RETURNS fichamedicainfomedrecetarioitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicainfomedrecetarioitemcc:= current_timestamp;
    delete from sincro.fichamedicainfomedrecetarioitem WHERE idfichamedicainfomedrecetarioitem= fila.idfichamedicainfomedrecetarioitem AND idcentrofichamedicainfomedrecetarioitem= fila.idcentrofichamedicainfomedrecetarioitem AND TRUE;
    RETURN fila;
    END;
    $function$
