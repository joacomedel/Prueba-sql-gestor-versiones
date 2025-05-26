CREATE OR REPLACE FUNCTION public.insertarccprueba(fila prueba)
 RETURNS prueba
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pruebacc:= current_timestamp;
    UPDATE sincro.prueba SET nrodoc= fila.nrodoc, mutu= fila.mutu, nromutu= fila.nromutu, legajosiu= fila.legajosiu, pruebacc= fila.pruebacc, tipodoc= fila.tipodoc WHERE tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prueba(nrodoc, mutu, nromutu, legajosiu, pruebacc, tipodoc) VALUES (fila.nrodoc, fila.mutu, fila.nromutu, fila.legajosiu, fila.pruebacc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
