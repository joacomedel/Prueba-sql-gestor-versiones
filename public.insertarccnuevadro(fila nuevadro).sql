CREATE OR REPLACE FUNCTION public.insertarccnuevadro(fila nuevadro)
 RETURNS nuevadro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.nuevadrocc:= current_timestamp;
    UPDATE sincro.nuevadro SET idnuevadro= fila.idnuevadro, nddescripcion= fila.nddescripcion, nuevadrocc= fila.nuevadrocc WHERE idnuevadro= fila.idnuevadro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.nuevadro(idnuevadro, nddescripcion, nuevadrocc) VALUES (fila.idnuevadro, fila.nddescripcion, fila.nuevadrocc);
    END IF;
    RETURN fila;
    END;
    $function$
