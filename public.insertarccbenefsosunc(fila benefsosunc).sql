CREATE OR REPLACE FUNCTION public.insertarccbenefsosunc(fila benefsosunc)
 RETURNS benefsosunc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.benefsosunccc:= current_timestamp;
    UPDATE sincro.benefsosunc SET barramutu= fila.barramutu, barratitu= fila.barratitu, benefsosunccc= fila.benefsosunccc, estaactivo= fila.estaactivo, idestado= fila.idestado, idosexterna= fila.idosexterna, idvin= fila.idvin, mutual= fila.mutual, nrodoc= fila.nrodoc, nrodoctitu= fila.nrodoctitu, nromututitu= fila.nromututitu, nroosexterna= fila.nroosexterna, tipodoc= fila.tipodoc, tipodoctitu= fila.tipodoctitu WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.benefsosunc(barramutu, barratitu, benefsosunccc, estaactivo, idestado, idosexterna, idvin, mutual, nrodoc, nrodoctitu, nromututitu, nroosexterna, tipodoc, tipodoctitu) VALUES (fila.barramutu, fila.barratitu, fila.benefsosunccc, fila.estaactivo, fila.idestado, fila.idosexterna, fila.idvin, fila.mutual, fila.nrodoc, fila.nrodoctitu, fila.nromututitu, fila.nroosexterna, fila.tipodoc, fila.tipodoctitu);
    END IF;
    RETURN fila;
    END;
    $function$
