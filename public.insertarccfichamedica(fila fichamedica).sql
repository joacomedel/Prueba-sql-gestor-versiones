CREATE OR REPLACE FUNCTION public.insertarccfichamedica(fila fichamedica)
 RETURNS fichamedica
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicacc:= current_timestamp;
    UPDATE sincro.fichamedica SET fichamedicacc= fila.fichamedicacc, fmdescripcion= fila.fmdescripcion, fmfechacreacion= fila.fmfechacreacion, idauditoriatipo= fila.idauditoriatipo, idcentrofichamedica= fila.idcentrofichamedica, idfichamedica= fila.idfichamedica, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE idcentrofichamedica= fila.idcentrofichamedica AND idfichamedica= fila.idfichamedica AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedica(fichamedicacc, fmdescripcion, fmfechacreacion, idauditoriatipo, idcentrofichamedica, idfichamedica, nrodoc, tipodoc) VALUES (fila.fichamedicacc, fila.fmdescripcion, fila.fmfechacreacion, fila.idauditoriatipo, fila.idcentrofichamedica, fila.idfichamedica, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
