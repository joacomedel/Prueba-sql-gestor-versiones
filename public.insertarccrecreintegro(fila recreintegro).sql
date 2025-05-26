CREATE OR REPLACE FUNCTION public.insertarccrecreintegro(fila recreintegro)
 RETURNS recreintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recreintegrocc:= current_timestamp;
    UPDATE sincro.recreintegro SET apellidoaf= fila.apellidoaf, barra= fila.barra, idcentroregional= fila.idcentroregional, idcentroreintegro= fila.idcentroreintegro, idrecepcion= fila.idrecepcion, localidad= fila.localidad, nombreaf= fila.nombreaf, nrodoc= fila.nrodoc, recreintegrocc= fila.recreintegrocc WHERE idcentroregional= fila.idcentroregional AND idrecepcion= fila.idrecepcion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recreintegro(apellidoaf, barra, idcentroregional, idcentroreintegro, idrecepcion, localidad, nombreaf, nrodoc, recreintegrocc) VALUES (fila.apellidoaf, fila.barra, fila.idcentroregional, fila.idcentroreintegro, fila.idrecepcion, fila.localidad, fila.nombreaf, fila.nrodoc, fila.recreintegrocc);
    END IF;
    RETURN fila;
    END;
    $function$
