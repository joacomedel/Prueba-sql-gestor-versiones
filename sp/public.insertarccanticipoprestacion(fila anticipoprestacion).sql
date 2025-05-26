CREATE OR REPLACE FUNCTION public.insertarccanticipoprestacion(fila anticipoprestacion)
 RETURNS anticipoprestacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.anticipoprestacioncc:= current_timestamp;
    UPDATE sincro.anticipoprestacion SET anio= fila.anio, anticipoprestacioncc= fila.anticipoprestacioncc, cantidad= fila.cantidad, idcentroregional= fila.idcentroregional, importe= fila.importe, nroanticipo= fila.nroanticipo, observacion= fila.observacion, prestacion= fila.prestacion, tipoprestacion= fila.tipoprestacion WHERE anio= fila.anio AND nroanticipo= fila.nroanticipo AND tipoprestacion= fila.tipoprestacion AND idcentroregional= fila.idcentroregional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.anticipoprestacion(anio, anticipoprestacioncc, cantidad, idcentroregional, importe, nroanticipo, observacion, prestacion, tipoprestacion) VALUES (fila.anio, fila.anticipoprestacioncc, fila.cantidad, fila.idcentroregional, fila.importe, fila.nroanticipo, fila.observacion, fila.prestacion, fila.tipoprestacion);
    END IF;
    RETURN fila;
    END;
    $function$
