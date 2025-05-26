CREATE OR REPLACE FUNCTION public.insertarccreintegroprestacion(fila reintegroprestacion)
 RETURNS reintegroprestacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegroprestacioncc:= current_timestamp;
    UPDATE sincro.reintegroprestacion SET anio= fila.anio, cantidad= fila.cantidad, idcentroregional= fila.idcentroregional, importe= fila.importe, nroreintegro= fila.nroreintegro, observacion= fila.observacion, prestacion= fila.prestacion, reintegroprestacioncc= fila.reintegroprestacioncc, tipoprestacion= fila.tipoprestacion WHERE anio= fila.anio AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND tipoprestacion= fila.tipoprestacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.reintegroprestacion(anio, cantidad, idcentroregional, importe, nroreintegro, observacion, prestacion, reintegroprestacioncc, tipoprestacion) VALUES (fila.anio, fila.cantidad, fila.idcentroregional, fila.importe, fila.nroreintegro, fila.observacion, fila.prestacion, fila.reintegroprestacioncc, fila.tipoprestacion);
    END IF;
    RETURN fila;
    END;
    $function$
