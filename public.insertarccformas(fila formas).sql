CREATE OR REPLACE FUNCTION public.insertarccformas(fila formas)
 RETURNS formas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.formascc:= current_timestamp;
    UPDATE sincro.formas SET fdescripcion= fila.fdescripcion, formascc= fila.formascc, idformas= fila.idformas WHERE idformas= fila.idformas AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.formas(fdescripcion, formascc, idformas) VALUES (fila.fdescripcion, fila.formascc, fila.idformas);
    END IF;
    RETURN fila;
    END;
    $function$
