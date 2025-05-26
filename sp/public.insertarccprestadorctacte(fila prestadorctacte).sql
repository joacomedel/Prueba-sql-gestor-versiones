CREATE OR REPLACE FUNCTION public.insertarccprestadorctacte(fila prestadorctacte)
 RETURNS prestadorctacte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadorctactecc:= current_timestamp;
    UPDATE sincro.prestadorctacte SET idcentroprestadorctacte= fila.idcentroprestadorctacte, idprestador= fila.idprestador, idprestadorctacte= fila.idprestadorctacte, prestadorctactecc= fila.prestadorctactecc WHERE idprestadorctacte= fila.idprestadorctacte AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prestadorctacte(idcentroprestadorctacte, idprestador, idprestadorctacte, prestadorctactecc) VALUES (fila.idcentroprestadorctacte, fila.idprestador, fila.idprestadorctacte, fila.prestadorctactecc);
    END IF;
    RETURN fila;
    END;
    $function$
