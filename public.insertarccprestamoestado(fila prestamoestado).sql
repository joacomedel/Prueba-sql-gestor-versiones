CREATE OR REPLACE FUNCTION public.insertarccprestamoestado(fila prestamoestado)
 RETURNS prestamoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestamoestadocc:= current_timestamp;
    UPDATE sincro.prestamoestado SET idcentroprestamo= fila.idcentroprestamo, idcentroprestamoestado= fila.idcentroprestamoestado, idprestamo= fila.idprestamo, idprestamoestado= fila.idprestamoestado, idprestamoestadotipos= fila.idprestamoestadotipos, pefechafin= fila.pefechafin, pefechaini= fila.pefechaini, prestamoestadocc= fila.prestamoestadocc WHERE idcentroprestamoestado= fila.idcentroprestamoestado AND idprestamoestado= fila.idprestamoestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prestamoestado(idcentroprestamo, idcentroprestamoestado, idprestamo, idprestamoestado, idprestamoestadotipos, pefechafin, pefechaini, prestamoestadocc) VALUES (fila.idcentroprestamo, fila.idcentroprestamoestado, fila.idprestamo, fila.idprestamoestado, fila.idprestamoestadotipos, fila.pefechafin, fila.pefechaini, fila.prestamoestadocc);
    END IF;
    RETURN fila;
    END;
    $function$
