CREATE OR REPLACE FUNCTION public.insertarccfichamedicainfo(fila fichamedicainfo)
 RETURNS fichamedicainfo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicainfocc:= current_timestamp;
    UPDATE sincro.fichamedicainfo SET idfichamedicainfotipos= fila.idfichamedicainfotipos, idfichamedicainfo= fila.idfichamedicainfo, idcentrofichamedicatratamiento= fila.idcentrofichamedicatratamiento, idcentrofichamedicainfo= fila.idcentrofichamedicainfo, fichamedicainfocc= fila.fichamedicainfocc, idfichamedicatratamiento= fila.idfichamedicatratamiento, fmidescripcion= fila.fmidescripcion, fmifecha= fila.fmifecha, fmiauditor= fila.fmiauditor WHERE idfichamedicainfo= fila.idfichamedicainfo AND idcentrofichamedicainfo= fila.idcentrofichamedicainfo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicainfo(idfichamedicainfotipos, idfichamedicainfo, idcentrofichamedicatratamiento, idcentrofichamedicainfo, fichamedicainfocc, idfichamedicatratamiento, fmidescripcion, fmifecha, fmiauditor) VALUES (fila.idfichamedicainfotipos, fila.idfichamedicainfo, fila.idcentrofichamedicatratamiento, fila.idcentrofichamedicainfo, fila.fichamedicainfocc, fila.idfichamedicatratamiento, fila.fmidescripcion, fila.fmifecha, fila.fmiauditor);
    END IF;
    RETURN fila;
    END;
    $function$
