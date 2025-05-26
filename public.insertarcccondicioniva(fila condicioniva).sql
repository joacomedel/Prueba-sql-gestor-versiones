CREATE OR REPLACE FUNCTION public.insertarcccondicioniva(fila condicioniva)
 RETURNS condicioniva
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.condicionivacc:= current_timestamp;
    UPDATE sincro.condicioniva SET condicionivacc= fila.condicionivacc, descripcioniva= fila.descripcioniva, idcondicioniva= fila.idcondicioniva WHERE idcondicioniva= fila.idcondicioniva AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.condicioniva(condicionivacc, descripcioniva, idcondicioniva) VALUES (fila.condicionivacc, fila.descripcioniva, fila.idcondicioniva);
    END IF;
    RETURN fila;
    END;
    $function$
