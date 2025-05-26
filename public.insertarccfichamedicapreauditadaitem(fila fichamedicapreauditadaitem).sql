CREATE OR REPLACE FUNCTION public.insertarccfichamedicapreauditadaitem(fila fichamedicapreauditadaitem)
 RETURNS fichamedicapreauditadaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadaitemcc:= current_timestamp;
    UPDATE sincro.fichamedicapreauditadaitem SET centro= fila.centro, fichamedicapreauditadaitemcc= fila.fichamedicapreauditadaitemcc, fmpaifechaingreso= fila.fmpaifechaingreso, idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada, idfichamedicapreauditada= fila.idfichamedicapreauditada, iditem= fila.iditem, nroorden= fila.nroorden WHERE centro= fila.centro AND idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada AND idfichamedicapreauditada= fila.idfichamedicapreauditada AND iditem= fila.iditem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicapreauditadaitem(centro, fichamedicapreauditadaitemcc, fmpaifechaingreso, idcentrofichamedicapreauditada, idfichamedicapreauditada, iditem, nroorden) VALUES (fila.centro, fila.fichamedicapreauditadaitemcc, fila.fmpaifechaingreso, fila.idcentrofichamedicapreauditada, fila.idfichamedicapreauditada, fila.iditem, fila.nroorden);
    END IF;
    RETURN fila;
    END;
    $function$
