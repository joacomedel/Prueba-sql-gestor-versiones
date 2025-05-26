CREATE OR REPLACE FUNCTION public.insertarccfichamedicaitememisiones(fila fichamedicaitememisiones)
 RETURNS fichamedicaitememisiones
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitememisionescc:= current_timestamp;
    UPDATE sincro.fichamedicaitememisiones SET anio= fila.anio, centro= fila.centro, fichamedicaitememisionescc= fila.fichamedicaitememisionescc, fmieimporte= fila.fmieimporte, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idcentrofichamedicaitememisiones= fila.idcentrofichamedicaitememisiones, idcentroregional= fila.idcentroregional, idfichamedicaitem= fila.idfichamedicaitem, idfichamedicaitememisiones= fila.idfichamedicaitememisiones, nroorden= fila.nroorden, nroreintegro= fila.nroreintegro WHERE idcentrofichamedicaitememisiones= fila.idcentrofichamedicaitememisiones AND idfichamedicaitememisiones= fila.idfichamedicaitememisiones AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicaitememisiones(anio, centro, fichamedicaitememisionescc, fmieimporte, idcentrofichamedicaitem, idcentrofichamedicaitememisiones, idcentroregional, idfichamedicaitem, idfichamedicaitememisiones, nroorden, nroreintegro) VALUES (fila.anio, fila.centro, fila.fichamedicaitememisionescc, fila.fmieimporte, fila.idcentrofichamedicaitem, fila.idcentrofichamedicaitememisiones, fila.idcentroregional, fila.idfichamedicaitem, fila.idfichamedicaitememisiones, fila.nroorden, fila.nroreintegro);
    END IF;
    RETURN fila;
    END;
    $function$
