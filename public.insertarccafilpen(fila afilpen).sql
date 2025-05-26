CREATE OR REPLACE FUNCTION public.insertarccafilpen(fila afilpen)
 RETURNS afilpen
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilpencc:= current_timestamp;
    UPDATE sincro.afilpen SET afilpencc= fila.afilpencc, idcert= fila.idcert, ingreso= fila.ingreso, nrodoc= fila.nrodoc, nrodoctitu= fila.nrodoctitu, tipodoc= fila.tipodoc, tipodoctitu= fila.tipodoctitu, trabaja= fila.trabaja WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afilpen(afilpencc, idcert, ingreso, nrodoc, nrodoctitu, tipodoc, tipodoctitu, trabaja) VALUES (fila.afilpencc, fila.idcert, fila.ingreso, fila.nrodoc, fila.nrodoctitu, fila.tipodoc, fila.tipodoctitu, fila.trabaja);
    END IF;
    RETURN fila;
    END;
    $function$
