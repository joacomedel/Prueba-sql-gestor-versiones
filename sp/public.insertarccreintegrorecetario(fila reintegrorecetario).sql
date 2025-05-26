CREATE OR REPLACE FUNCTION public.insertarccreintegrorecetario(fila reintegrorecetario)
 RETURNS reintegrorecetario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegrorecetariocc:= current_timestamp;
    UPDATE sincro.reintegrorecetario SET anio= fila.anio, centro= fila.centro, idcentroregional= fila.idcentroregional, nrorecetario= fila.nrorecetario, nroreintegro= fila.nroreintegro, reintegrorecetariocc= fila.reintegrorecetariocc WHERE anio= fila.anio AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.reintegrorecetario(anio, centro, idcentroregional, nrorecetario, nroreintegro, reintegrorecetariocc) VALUES (fila.anio, fila.centro, fila.idcentroregional, fila.nrorecetario, fila.nroreintegro, fila.reintegrorecetariocc);
    END IF;
    RETURN fila;
    END;
    $function$
