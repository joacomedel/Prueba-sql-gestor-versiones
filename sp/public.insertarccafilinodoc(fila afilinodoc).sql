CREATE OR REPLACE FUNCTION public.insertarccafilinodoc(fila afilinodoc)
 RETURNS afilinodoc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilinodoccc:= current_timestamp;
    UPDATE sincro.afilinodoc SET afilinodoccc= fila.afilinodoccc, legajosiu= fila.legajosiu, mutu= fila.mutu, nrodoc= fila.nrodoc, nromutu= fila.nromutu, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afilinodoc(afilinodoccc, legajosiu, mutu, nrodoc, nromutu, tipodoc) VALUES (fila.afilinodoccc, fila.legajosiu, fila.mutu, fila.nrodoc, fila.nromutu, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
