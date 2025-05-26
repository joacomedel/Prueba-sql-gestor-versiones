CREATE OR REPLACE FUNCTION public.insertarccfichamedicaemisionestado(fila fichamedicaemisionestado)
 RETURNS fichamedicaemisionestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaemisionestadocc:= current_timestamp;
    UPDATE sincro.fichamedicaemisionestado SET fichamedicaemisionestadocc= fila.fichamedicaemisionestadocc, fmeedescripcion= fila.fmeedescripcion, fmeefechafin= fila.fmeefechafin, fmeefechaini= fila.fmeefechaini, idauditoriatipo= fila.idauditoriatipo, idcentrofichamedicaemisionestado= fila.idcentrofichamedicaemisionestado, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idfichamedicaemisionestado= fila.idfichamedicaemisionestado, idfichamedicaemisionestadotipo= fila.idfichamedicaemisionestadotipo, idfichamedicaitem= fila.idfichamedicaitem WHERE idcentrofichamedicaemisionestado= fila.idcentrofichamedicaemisionestado AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND idfichamedicaemisionestado= fila.idfichamedicaemisionestado AND idfichamedicaitem= fila.idfichamedicaitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicaemisionestado(fichamedicaemisionestadocc, fmeedescripcion, fmeefechafin, fmeefechaini, idauditoriatipo, idcentrofichamedicaemisionestado, idcentrofichamedicaitem, idfichamedicaemisionestado, idfichamedicaemisionestadotipo, idfichamedicaitem) VALUES (fila.fichamedicaemisionestadocc, fila.fmeedescripcion, fila.fmeefechafin, fila.fmeefechaini, fila.idauditoriatipo, fila.idcentrofichamedicaemisionestado, fila.idcentrofichamedicaitem, fila.idfichamedicaemisionestado, fila.idfichamedicaemisionestadotipo, fila.idfichamedicaitem);
    END IF;
    RETURN fila;
    END;
    $function$
