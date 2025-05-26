CREATE OR REPLACE FUNCTION public.insertarccafilreci(fila afilreci)
 RETURNS afilreci
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilrecicc:= current_timestamp;
    UPDATE sincro.afilreci SET afilrecicc= fila.afilrecicc, barra= fila.barra, fechavtoreci= fila.fechavtoreci, idestado= fila.idestado, idosreci= fila.idosreci, idreci= fila.idreci, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afilreci(afilrecicc, barra, fechavtoreci, idestado, idosreci, idreci, nrodoc, tipodoc) VALUES (fila.afilrecicc, fila.barra, fila.fechavtoreci, fila.idestado, fila.idosreci, fila.idreci, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
