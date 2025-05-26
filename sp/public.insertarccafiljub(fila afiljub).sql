CREATE OR REPLACE FUNCTION public.insertarccafiljub(fila afiljub)
 RETURNS afiljub
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afiljubcc:= current_timestamp;
    UPDATE sincro.afiljub SET afiljubcc= fila.afiljubcc, idcertpers= fila.idcertpers, ingreso= fila.ingreso, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc, trabaja= fila.trabaja, trabajaunc= fila.trabajaunc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afiljub(afiljubcc, idcertpers, ingreso, nrodoc, tipodoc, trabaja, trabajaunc) VALUES (fila.afiljubcc, fila.idcertpers, fila.ingreso, fila.nrodoc, fila.tipodoc, fila.trabaja, fila.trabajaunc);
    END IF;
    RETURN fila;
    END;
    $function$
