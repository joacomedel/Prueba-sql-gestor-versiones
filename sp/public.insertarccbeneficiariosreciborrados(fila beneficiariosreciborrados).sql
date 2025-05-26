CREATE OR REPLACE FUNCTION public.insertarccbeneficiariosreciborrados(fila beneficiariosreciborrados)
 RETURNS beneficiariosreciborrados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.beneficiariosreciborradoscc:= current_timestamp;
    UPDATE sincro.beneficiariosreciborrados SET barratitu= fila.barratitu, beneficiariosreciborradoscc= fila.beneficiariosreciborradoscc, borrado= fila.borrado, fechavtoreci= fila.fechavtoreci, idestado= fila.idestado, idreci= fila.idreci, idvin= fila.idvin, nrodoc= fila.nrodoc, nrodoctitu= fila.nrodoctitu, tipodoc= fila.tipodoc, tipodoctitu= fila.tipodoctitu WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.beneficiariosreciborrados(barratitu, beneficiariosreciborradoscc, borrado, fechavtoreci, idestado, idreci, idvin, nrodoc, nrodoctitu, tipodoc, tipodoctitu) VALUES (fila.barratitu, fila.beneficiariosreciborradoscc, fila.borrado, fila.fechavtoreci, fila.idestado, fila.idreci, fila.idvin, fila.nrodoc, fila.nrodoctitu, fila.tipodoc, fila.tipodoctitu);
    END IF;
    RETURN fila;
    END;
    $function$
