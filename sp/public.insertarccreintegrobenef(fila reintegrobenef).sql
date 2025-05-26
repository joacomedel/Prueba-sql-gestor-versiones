CREATE OR REPLACE FUNCTION public.insertarccreintegrobenef(fila reintegrobenef)
 RETURNS reintegrobenef
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegrobenefcc:= current_timestamp;
    UPDATE sincro.reintegrobenef SET anio= fila.anio, barra= fila.barra, idcentroregional= fila.idcentroregional, nrodoc= fila.nrodoc, nroreintegro= fila.nroreintegro, reintegrobenefcc= fila.reintegrobenefcc WHERE anio= fila.anio AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.reintegrobenef(anio, barra, idcentroregional, nrodoc, nroreintegro, reintegrobenefcc) VALUES (fila.anio, fila.barra, fila.idcentroregional, fila.nrodoc, fila.nroreintegro, fila.reintegrobenefcc);
    END IF;
    RETURN fila;
    END;
    $function$
