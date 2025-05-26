CREATE OR REPLACE FUNCTION public.insertarccafiliauto(fila afiliauto)
 RETURNS afiliauto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afiliautocc:= current_timestamp;
    UPDATE sincro.afiliauto SET afiliautocc= fila.afiliautocc, legajosiu= fila.legajosiu, mutu= fila.mutu, nrodoc= fila.nrodoc, nromutu= fila.nromutu, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afiliauto(afiliautocc, legajosiu, mutu, nrodoc, nromutu, tipodoc) VALUES (fila.afiliautocc, fila.legajosiu, fila.mutu, fila.nrodoc, fila.nromutu, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
