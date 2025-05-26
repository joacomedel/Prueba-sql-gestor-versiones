CREATE OR REPLACE FUNCTION public.insertarccgrupoacompaniante(fila grupoacompaniante)
 RETURNS grupoacompaniante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.grupoacompaniantecc:= current_timestamp;
    UPDATE sincro.grupoacompaniante SET apellido= fila.apellido, fechanac= fila.fechanac, gaborrado= fila.gaborrado, grupoacompaniantecc= fila.grupoacompaniantecc, idcentroconsumoturismo= fila.idcentroconsumoturismo, idconsumoturismo= fila.idconsumoturismo, idvinculo= fila.idvinculo, invitado= fila.invitado, nombres= fila.nombres, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE idcentroconsumoturismo= fila.idcentroconsumoturismo AND idconsumoturismo= fila.idconsumoturismo AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.grupoacompaniante(apellido, fechanac, gaborrado, grupoacompaniantecc, idcentroconsumoturismo, idconsumoturismo, idvinculo, invitado, nombres, nrodoc, tipodoc) VALUES (fila.apellido, fila.fechanac, fila.gaborrado, fila.grupoacompaniantecc, fila.idcentroconsumoturismo, fila.idconsumoturismo, fila.idvinculo, fila.invitado, fila.nombres, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
