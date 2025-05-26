CREATE OR REPLACE FUNCTION public.eliminarccreintegroprestacion(fila reintegroprestacion)
 RETURNS reintegroprestacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegroprestacioncc:= current_timestamp;
    delete from sincro.reintegroprestacion WHERE anio= fila.anio AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND tipoprestacion= fila.tipoprestacion AND TRUE;
    RETURN fila;
    END;
    $function$
