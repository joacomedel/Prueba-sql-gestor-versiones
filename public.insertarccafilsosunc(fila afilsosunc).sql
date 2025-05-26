CREATE OR REPLACE FUNCTION public.insertarccafilsosunc(fila afilsosunc)
 RETURNS afilsosunc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilsosunccc:= current_timestamp;
    UPDATE sincro.afilsosunc SET afilsosunccc= fila.afilsosunccc, barra= fila.barra, ctacteexpendio= fila.ctacteexpendio, fechainiunc= fila.fechainiunc, idctacte= fila.idctacte, idestado= fila.idestado, idosexterna= fila.idosexterna, nrocuildni= fila.nrocuildni, nrocuilfin= fila.nrocuilfin, nrocuilini= fila.nrocuilini, nrodoc= fila.nrodoc, nroosexterna= fila.nroosexterna, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afilsosunc(afilsosunccc, barra, ctacteexpendio, fechainiunc, idctacte, idestado, idosexterna, nrocuildni, nrocuilfin, nrocuilini, nrodoc, nroosexterna, tipodoc) VALUES (fila.afilsosunccc, fila.barra, fila.ctacteexpendio, fila.fechainiunc, fila.idctacte, fila.idestado, fila.idosexterna, fila.nrocuildni, fila.nrocuilfin, fila.nrocuilini, fila.nrodoc, fila.nroosexterna, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
