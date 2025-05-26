CREATE OR REPLACE FUNCTION public.insertarccreintegroestudio(fila reintegroestudio)
 RETURNS reintegroestudio
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegroestudiocc:= current_timestamp;
    UPDATE sincro.reintegroestudio SET cantidad= fila.cantidad, idcentroregional= fila.idcentroregional, idestudio= fila.idestudio, idrecepcion= fila.idrecepcion, reintegroestudiocc= fila.reintegroestudiocc WHERE idcentroregional= fila.idcentroregional AND idestudio= fila.idestudio AND idrecepcion= fila.idrecepcion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.reintegroestudio(cantidad, idcentroregional, idestudio, idrecepcion, reintegroestudiocc) VALUES (fila.cantidad, fila.idcentroregional, fila.idestudio, fila.idrecepcion, fila.reintegroestudiocc);
    END IF;
    RETURN fila;
    END;
    $function$
