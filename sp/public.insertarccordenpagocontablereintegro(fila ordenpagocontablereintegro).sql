CREATE OR REPLACE FUNCTION public.insertarccordenpagocontablereintegro(fila ordenpagocontablereintegro)
 RETURNS ordenpagocontablereintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocontablereintegrocc:= current_timestamp;
    UPDATE sincro.ordenpagocontablereintegro SET anio= fila.anio, idcentroordenpagocontable= fila.idcentroordenpagocontable, idcentroregional= fila.idcentroregional, idordenpagocontable= fila.idordenpagocontable, nroreintegro= fila.nroreintegro, opcrconotp= fila.opcrconotp, opcrobservacion= fila.opcrobservacion, ordenpagocontablereintegrocc= fila.ordenpagocontablereintegrocc WHERE idordenpagocontable= fila.idordenpagocontable AND idcentroregional= fila.idcentroregional AND idcentroordenpagocontable= fila.idcentroordenpagocontable AND nroreintegro= fila.nroreintegro AND anio= fila.anio AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenpagocontablereintegro(anio, idcentroordenpagocontable, idcentroregional, idordenpagocontable, nroreintegro, opcrconotp, opcrobservacion, ordenpagocontablereintegrocc) VALUES (fila.anio, fila.idcentroordenpagocontable, fila.idcentroregional, fila.idordenpagocontable, fila.nroreintegro, fila.opcrconotp, fila.opcrobservacion, fila.ordenpagocontablereintegrocc);
    END IF;
    RETURN fila;
    END;
    $function$
