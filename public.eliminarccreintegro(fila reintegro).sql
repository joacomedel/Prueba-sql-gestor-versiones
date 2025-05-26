CREATE OR REPLACE FUNCTION public.eliminarccreintegro(fila reintegro)
 RETURNS reintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegrocc:= current_timestamp;
    delete from sincro.reintegro WHERE anio= fila.anio AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND TRUE;
    RETURN fila;
    END;
    $function$
