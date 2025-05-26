CREATE OR REPLACE FUNCTION public.insertarccbeneficiariosborrados(fila beneficiariosborrados)
 RETURNS beneficiariosborrados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.beneficiariosborradoscc:= current_timestamp;
    UPDATE sincro.beneficiariosborrados SET barramutu= fila.barramutu, barratitu= fila.barratitu, beneficiariosborradoscc= fila.beneficiariosborradoscc, borrado= fila.borrado, idestado= fila.idestado, idosexterna= fila.idosexterna, idvin= fila.idvin, mutual= fila.mutual, nrodoc= fila.nrodoc, nrodoctitu= fila.nrodoctitu, nromututitu= fila.nromututitu, nroosexterna= fila.nroosexterna, tipodoc= fila.tipodoc, tipodoctitu= fila.tipodoctitu WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.beneficiariosborrados(barramutu, barratitu, beneficiariosborradoscc, borrado, idestado, idosexterna, idvin, mutual, nrodoc, nrodoctitu, nromututitu, nroosexterna, tipodoc, tipodoctitu) VALUES (fila.barramutu, fila.barratitu, fila.beneficiariosborradoscc, fila.borrado, fila.idestado, fila.idosexterna, fila.idvin, fila.mutual, fila.nrodoc, fila.nrodoctitu, fila.nromututitu, fila.nroosexterna, fila.tipodoc, fila.tipodoctitu);
    END IF;
    RETURN fila;
    END;
    $function$
