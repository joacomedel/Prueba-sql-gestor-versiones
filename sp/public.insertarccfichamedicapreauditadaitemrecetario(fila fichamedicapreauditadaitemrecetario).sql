CREATE OR REPLACE FUNCTION public.insertarccfichamedicapreauditadaitemrecetario(fila fichamedicapreauditadaitemrecetario)
 RETURNS fichamedicapreauditadaitemrecetario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadaitemrecetariocc:= current_timestamp;
    UPDATE sincro.fichamedicapreauditadaitemrecetario SET idrecetarioitem= fila.idrecetarioitem, centro= fila.centro, idcentrorecetarioitem= fila.idcentrorecetarioitem, fmpaifechaingreso= fila.fmpaifechaingreso, idfichamedicapreauditada= fila.idfichamedicapreauditada, idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada, fichamedicapreauditadaitemrecetariocc= fila.fichamedicapreauditadaitemrecetariocc WHERE idrecetarioitem= fila.idrecetarioitem AND idcentrorecetarioitem= fila.idcentrorecetarioitem AND idfichamedicapreauditada= fila.idfichamedicapreauditada AND idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicapreauditadaitemrecetario(idrecetarioitem, centro, idcentrorecetarioitem, fmpaifechaingreso, idfichamedicapreauditada, idcentrofichamedicapreauditada, fichamedicapreauditadaitemrecetariocc) VALUES (fila.idrecetarioitem, fila.centro, fila.idcentrorecetarioitem, fila.fmpaifechaingreso, fila.idfichamedicapreauditada, fila.idcentrofichamedicapreauditada, fila.fichamedicapreauditadaitemrecetariocc);
    END IF;
    RETURN fila;
    END;
    $function$
