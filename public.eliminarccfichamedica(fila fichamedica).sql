CREATE OR REPLACE FUNCTION public.eliminarccfichamedica(fila fichamedica)
 RETURNS fichamedica
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicacc:= current_timestamp;
    delete from sincro.fichamedica WHERE idcentrofichamedica= fila.idcentrofichamedica AND idfichamedica= fila.idfichamedica AND TRUE;
    RETURN fila;
    END;
    $function$
