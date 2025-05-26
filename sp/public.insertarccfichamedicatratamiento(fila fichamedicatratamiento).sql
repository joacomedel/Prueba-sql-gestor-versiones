CREATE OR REPLACE FUNCTION public.insertarccfichamedicatratamiento(fila fichamedicatratamiento)
 RETURNS fichamedicatratamiento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicatratamientocc:= current_timestamp;
    UPDATE sincro.fichamedicatratamiento SET fmtfechainicio= fila.fmtfechainicio, idcentrofichamedicatratamiento= fila.idcentrofichamedicatratamiento, idfichamedicatratamiento= fila.idfichamedicatratamiento, idfichamedicatratamientotipo= fila.idfichamedicatratamientotipo, idcentrofichamedica= fila.idcentrofichamedica, idfichamedica= fila.idfichamedica, fichamedicatratamientocc= fila.fichamedicatratamientocc WHERE idcentrofichamedicatratamiento= fila.idcentrofichamedicatratamiento AND idfichamedicatratamiento= fila.idfichamedicatratamiento AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicatratamiento(fmtfechainicio, idcentrofichamedicatratamiento, idfichamedicatratamiento, idfichamedicatratamientotipo, idcentrofichamedica, idfichamedica, fichamedicatratamientocc) VALUES (fila.fmtfechainicio, fila.idcentrofichamedicatratamiento, fila.idfichamedicatratamiento, fila.idfichamedicatratamientotipo, fila.idcentrofichamedica, fila.idfichamedica, fila.fichamedicatratamientocc);
    END IF;
    RETURN fila;
    END;
    $function$
