CREATE OR REPLACE FUNCTION public.insertarcccargo(fila cargo)
 RETURNS cargo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cargocc:= current_timestamp;
    UPDATE sincro.cargo SET cargocc= fila.cargocc, fechafinlab= fila.fechafinlab, fechainilab= fila.fechainilab, idcargo= fila.idcargo, idcateg= fila.idcateg, iddepen= fila.iddepen, legajosiu= fila.legajosiu, nrodoc= fila.nrodoc, tellab= fila.tellab, tipodesig= fila.tipodesig, tipodoc= fila.tipodoc WHERE idcargo= fila.idcargo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cargo(cargocc, fechafinlab, fechainilab, idcargo, idcateg, iddepen, legajosiu, nrodoc, tellab, tipodesig, tipodoc) VALUES (fila.cargocc, fila.fechafinlab, fila.fechainilab, fila.idcargo, fila.idcateg, fila.iddepen, fila.legajosiu, fila.nrodoc, fila.tellab, fila.tipodesig, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
