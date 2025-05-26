CREATE OR REPLACE FUNCTION public.insertarccbenefreci(fila benefreci)
 RETURNS benefreci
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.benefrecicc:= current_timestamp;
    UPDATE sincro.benefreci SET barratitu= fila.barratitu, benefrecicc= fila.benefrecicc, fechavtoreci= fila.fechavtoreci, idestado= fila.idestado, idreci= fila.idreci, idvin= fila.idvin, nrodoc= fila.nrodoc, nrodoctitu= fila.nrodoctitu, tipodoc= fila.tipodoc, tipodoctitu= fila.tipodoctitu WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.benefreci(barratitu, benefrecicc, fechavtoreci, idestado, idreci, idvin, nrodoc, nrodoctitu, tipodoc, tipodoctitu) VALUES (fila.barratitu, fila.benefrecicc, fila.fechavtoreci, fila.idestado, fila.idreci, fila.idvin, fila.nrodoc, fila.nrodoctitu, fila.tipodoc, fila.tipodoctitu);
    END IF;
    RETURN fila;
    END;
    $function$
