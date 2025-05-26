CREATE OR REPLACE FUNCTION public.insertarccrecafiliacion(fila recafiliacion)
 RETURNS recafiliacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recafiliacioncc:= current_timestamp;
    UPDATE sincro.recafiliacion SET apellidoaf= fila.apellidoaf, idcentroregional= fila.idcentroregional, idrecepcion= fila.idrecepcion, nombreaf= fila.nombreaf, recafiliacioncc= fila.recafiliacioncc, tipoafiliacion= fila.tipoafiliacion WHERE idrecepcion= fila.idrecepcion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recafiliacion(apellidoaf, idcentroregional, idrecepcion, nombreaf, recafiliacioncc, tipoafiliacion) VALUES (fila.apellidoaf, fila.idcentroregional, fila.idrecepcion, fila.nombreaf, fila.recafiliacioncc, fila.tipoafiliacion);
    END IF;
    RETURN fila;
    END;
    $function$
