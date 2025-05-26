CREATE OR REPLACE FUNCTION public.insertarccfichamedicapreauditadaitemconsulta(fila fichamedicapreauditadaitemconsulta)
 RETURNS fichamedicapreauditadaitemconsulta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadaitemconsultacc:= current_timestamp;
    UPDATE sincro.fichamedicapreauditadaitemconsulta SET centro= fila.centro, fichamedicapreauditadaitemconsultacc= fila.fichamedicapreauditadaitemconsultacc, fmpaifechaingres= fila.fmpaifechaingres, idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada, idfichamedicapreauditada= fila.idfichamedicapreauditada, nroorden= fila.nroorden WHERE centro= fila.centro AND idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada AND idfichamedicapreauditada= fila.idfichamedicapreauditada AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicapreauditadaitemconsulta(centro, fichamedicapreauditadaitemconsultacc, fmpaifechaingres, idcentrofichamedicapreauditada, idfichamedicapreauditada, nroorden) VALUES (fila.centro, fila.fichamedicapreauditadaitemconsultacc, fila.fmpaifechaingres, fila.idcentrofichamedicapreauditada, fila.idfichamedicapreauditada, fila.nroorden);
    END IF;
    RETURN fila;
    END;
    $function$
