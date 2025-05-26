CREATE OR REPLACE FUNCTION public.eliminarccreintegrobenef(fila reintegrobenef)
 RETURNS reintegrobenef
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegrobenefcc:= current_timestamp;
    delete from sincro.reintegrobenef WHERE anio= fila.anio AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND TRUE;
    RETURN fila;
    END;
    $function$
