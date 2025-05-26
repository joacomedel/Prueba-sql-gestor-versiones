CREATE OR REPLACE FUNCTION public.insertarccafilidoc(fila afilidoc)
 RETURNS afilidoc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilidoccc:= current_timestamp;
    UPDATE sincro.afilidoc SET afilidoccc= fila.afilidoccc, legajosiu= fila.legajosiu, mutu= fila.mutu, nrodoc= fila.nrodoc, nromutu= fila.nromutu, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afilidoc(afilidoccc, legajosiu, mutu, nrodoc, nromutu, tipodoc) VALUES (fila.afilidoccc, fila.legajosiu, fila.mutu, fila.nrodoc, fila.nromutu, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
