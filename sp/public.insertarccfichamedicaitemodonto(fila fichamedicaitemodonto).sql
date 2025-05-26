CREATE OR REPLACE FUNCTION public.insertarccfichamedicaitemodonto(fila fichamedicaitemodonto)
 RETURNS fichamedicaitemodonto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitemodontocc:= current_timestamp;
    UPDATE sincro.fichamedicaitemodonto SET fichamedicaitemodontocc= fila.fichamedicaitemodontocc, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idcentrofichamedicaitemodonto= fila.idcentrofichamedicaitemodonto, idfichamedicaitem= fila.idfichamedicaitem, idfichamedicaitemodonto= fila.idfichamedicaitemodonto, idletradental= fila.idletradental, idpiezadental= fila.idpiezadental, idzonadental= fila.idzonadental WHERE idcentrofichamedicaitemodonto= fila.idcentrofichamedicaitemodonto AND idfichamedicaitemodonto= fila.idfichamedicaitemodonto AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicaitemodonto(fichamedicaitemodontocc, idcentrofichamedicaitem, idcentrofichamedicaitemodonto, idfichamedicaitem, idfichamedicaitemodonto, idletradental, idpiezadental, idzonadental) VALUES (fila.fichamedicaitemodontocc, fila.idcentrofichamedicaitem, fila.idcentrofichamedicaitemodonto, fila.idfichamedicaitem, fila.idfichamedicaitemodonto, fila.idletradental, fila.idpiezadental, fila.idzonadental);
    END IF;
    RETURN fila;
    END;
    $function$
