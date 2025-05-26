CREATE OR REPLACE FUNCTION public.insertarccfichamedicaitempendiente(fila fichamedicaitempendiente)
 RETURNS fichamedicaitempendiente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitempendientecc:= current_timestamp;
    UPDATE sincro.fichamedicaitempendiente SET anio= fila.anio, fichamedicaitempendientecc= fila.fichamedicaitempendientecc, fmpfecha= fila.fmpfecha, idauditoriatipo= fila.idauditoriatipo, idcentrofichamedica= fila.idcentrofichamedica, idcentrofichamedicaitempendiente= fila.idcentrofichamedicaitempendiente, idcentroregional= fila.idcentroregional, idfichamedica= fila.idfichamedica, idfichamedicaitempendiente= fila.idfichamedicaitempendiente, nrodoc= fila.nrodoc, nroreintegro= fila.nroreintegro, tipodoc= fila.tipodoc WHERE idcentrofichamedicaitempendiente= fila.idcentrofichamedicaitempendiente AND idfichamedicaitempendiente= fila.idfichamedicaitempendiente AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicaitempendiente(anio, fichamedicaitempendientecc, fmpfecha, idauditoriatipo, idcentrofichamedica, idcentrofichamedicaitempendiente, idcentroregional, idfichamedica, idfichamedicaitempendiente, nrodoc, nroreintegro, tipodoc) VALUES (fila.anio, fila.fichamedicaitempendientecc, fila.fmpfecha, fila.idauditoriatipo, fila.idcentrofichamedica, fila.idcentrofichamedicaitempendiente, fila.idcentroregional, fila.idfichamedica, fila.idfichamedicaitempendiente, fila.nrodoc, fila.nroreintegro, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
