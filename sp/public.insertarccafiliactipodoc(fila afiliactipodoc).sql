CREATE OR REPLACE FUNCTION public.insertarccafiliactipodoc(fila afiliactipodoc)
 RETURNS afiliactipodoc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afiliactipodoccc:= current_timestamp;
    UPDATE sincro.afiliactipodoc SET afiliactipodoccc= fila.afiliactipodoccc, iddocafil= fila.iddocafil, idrecepcion= fila.idrecepcion WHERE iddocafil= fila.iddocafil AND idrecepcion= fila.idrecepcion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afiliactipodoc(afiliactipodoccc, iddocafil, idrecepcion) VALUES (fila.afiliactipodoccc, fila.iddocafil, fila.idrecepcion);
    END IF;
    RETURN fila;
    END;
    $function$
