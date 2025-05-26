CREATE OR REPLACE FUNCTION public.insertarccfichamedicaitemsico(fila fichamedicaitemsico)
 RETURNS fichamedicaitemsico
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitemsicocc:= current_timestamp;
    UPDATE sincro.fichamedicaitemsico SET fichamedicaitemsicocc= fila.fichamedicaitemsicocc, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idcentrofichamedicaitemsico= fila.idcentrofichamedicaitemsico, iddiagnostico= fila.iddiagnostico, idfichamedicaitem= fila.idfichamedicaitem, idfichamedicaitemsico= fila.idfichamedicaitemsico WHERE idcentrofichamedicaitemsico= fila.idcentrofichamedicaitemsico AND idfichamedicaitemsico= fila.idfichamedicaitemsico AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicaitemsico(fichamedicaitemsicocc, idcentrofichamedicaitem, idcentrofichamedicaitemsico, iddiagnostico, idfichamedicaitem, idfichamedicaitemsico) VALUES (fila.fichamedicaitemsicocc, fila.idcentrofichamedicaitem, fila.idcentrofichamedicaitemsico, fila.iddiagnostico, fila.idfichamedicaitem, fila.idfichamedicaitemsico);
    END IF;
    RETURN fila;
    END;
    $function$
