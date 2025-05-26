CREATE OR REPLACE FUNCTION public.insertarccafilisos(fila afilisos)
 RETURNS afilisos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilisoscc:= current_timestamp;
    UPDATE sincro.afilisos SET afilisoscc= fila.afilisoscc, legajosiu= fila.legajosiu, mutu= fila.mutu, nrodoc= fila.nrodoc, nromutu= fila.nromutu, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afilisos(afilisoscc, legajosiu, mutu, nrodoc, nromutu, tipodoc) VALUES (fila.afilisoscc, fila.legajosiu, fila.mutu, fila.nrodoc, fila.nromutu, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
