CREATE OR REPLACE FUNCTION public.insertarccrecepcion(fila recepcion)
 RETURNS recepcion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recepcioncc:= current_timestamp;
    UPDATE sincro.recepcion SET apellido= fila.apellido, fecha= fila.fecha, idcentroregional= fila.idcentroregional, idcomprobante= fila.idcomprobante, idcorreo= fila.idcorreo, idrecepcion= fila.idrecepcion, idtiporecepcion= fila.idtiporecepcion, nombre= fila.nombre, recepcioncc= fila.recepcioncc WHERE idcentroregional= fila.idcentroregional AND idrecepcion= fila.idrecepcion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recepcion(apellido, fecha, idcentroregional, idcomprobante, idcorreo, idrecepcion, idtiporecepcion, nombre, recepcioncc) VALUES (fila.apellido, fila.fecha, fila.idcentroregional, fila.idcomprobante, fila.idcorreo, fila.idrecepcion, fila.idtiporecepcion, fila.nombre, fila.recepcioncc);
    END IF;
    RETURN fila;
    END;
    $function$
