CREATE OR REPLACE FUNCTION public.insertarccfichamedicapreauditadaodonto(fila fichamedicapreauditadaodonto)
 RETURNS fichamedicapreauditadaodonto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicapreauditadaodontocc:= current_timestamp;
    UPDATE sincro.fichamedicapreauditadaodonto SET fichamedicapreauditadaodontocc= fila.fichamedicapreauditadaodontocc, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idcentrofichamedicapreauditada= fila.idcentrofichamedicapreauditada, idcentrofichamedicapreauditadaodonto= fila.idcentrofichamedicapreauditadaodonto, idfichamedicaitem= fila.idfichamedicaitem, idfichamedicapreauditada= fila.idfichamedicapreauditada, idfichamedicapreauditadaodonto= fila.idfichamedicapreauditadaodonto, idletradental= fila.idletradental, idpiezadental= fila.idpiezadental, idzonadental= fila.idzonadental WHERE idcentrofichamedicapreauditadaodonto= fila.idcentrofichamedicapreauditadaodonto AND idfichamedicapreauditadaodonto= fila.idfichamedicapreauditadaodonto AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicapreauditadaodonto(fichamedicapreauditadaodontocc, idcentrofichamedicaitem, idcentrofichamedicapreauditada, idcentrofichamedicapreauditadaodonto, idfichamedicaitem, idfichamedicapreauditada, idfichamedicapreauditadaodonto, idletradental, idpiezadental, idzonadental) VALUES (fila.fichamedicapreauditadaodontocc, fila.idcentrofichamedicaitem, fila.idcentrofichamedicapreauditada, fila.idcentrofichamedicapreauditadaodonto, fila.idfichamedicaitem, fila.idfichamedicapreauditada, fila.idfichamedicapreauditadaodonto, fila.idletradental, fila.idpiezadental, fila.idzonadental);
    END IF;
    RETURN fila;
    END;
    $function$
