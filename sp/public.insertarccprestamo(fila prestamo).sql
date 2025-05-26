CREATE OR REPLACE FUNCTION public.insertarccprestamo(fila prestamo)
 RETURNS prestamo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestamocc:= current_timestamp;
    UPDATE sincro.prestamo SET fechaprestamo= fila.fechaprestamo, idcentroprestamo= fila.idcentroprestamo, idprestamo= fila.idprestamo, idprestamotipos= fila.idprestamotipos, importeprestamo= fila.importeprestamo, nrodoc= fila.nrodoc, prestamocc= fila.prestamocc, tipodoc= fila.tipodoc WHERE idcentroprestamo= fila.idcentroprestamo AND idprestamo= fila.idprestamo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prestamo(fechaprestamo, idcentroprestamo, idprestamo, idprestamotipos, importeprestamo, nrodoc, prestamocc, tipodoc) VALUES (fila.fechaprestamo, fila.idcentroprestamo, fila.idprestamo, fila.idprestamotipos, fila.importeprestamo, fila.nrodoc, fila.prestamocc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
