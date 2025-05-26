CREATE OR REPLACE FUNCTION public.eliminarccordenpagocontablereintegro(fila ordenpagocontablereintegro)
 RETURNS ordenpagocontablereintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocontablereintegrocc:= current_timestamp;
    delete from sincro.ordenpagocontablereintegro WHERE idordenpagocontable= fila.idordenpagocontable AND idcentroregional= fila.idcentroregional AND idcentroordenpagocontable= fila.idcentroordenpagocontable AND nroreintegro= fila.nroreintegro AND anio= fila.anio AND TRUE;
    RETURN fila;
    END;
    $function$
