CREATE OR REPLACE FUNCTION public.eliminarccreintegrorecetario(fila reintegrorecetario)
 RETURNS reintegrorecetario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegrorecetariocc:= current_timestamp;
    delete from sincro.reintegrorecetario WHERE anio= fila.anio AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND TRUE;
    RETURN fila;
    END;
    $function$
