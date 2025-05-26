CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaitemvale(fila far_ordenventaitemvale)
 RETURNS far_ordenventaitemvale
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemvalecc:= current_timestamp;
    UPDATE sincro.far_ordenventaitemvale SET far_ordenventaitemvalecc= fila.far_ordenventaitemvalecc, idcentroordenventaitemoriginal= fila.idcentroordenventaitemoriginal, idcentroordenventaitemvale= fila.idcentroordenventaitemvale, idordenventaitemoriginal= fila.idordenventaitemoriginal, idordenventaitemvale= fila.idordenventaitemvale, ovivcantidadentregada= fila.ovivcantidadentregada WHERE idcentroordenventaitemoriginal= fila.idcentroordenventaitemoriginal AND idcentroordenventaitemvale= fila.idcentroordenventaitemvale AND idordenventaitemoriginal= fila.idordenventaitemoriginal AND idordenventaitemvale= fila.idordenventaitemvale AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaitemvale(far_ordenventaitemvalecc, idcentroordenventaitemoriginal, idcentroordenventaitemvale, idordenventaitemoriginal, idordenventaitemvale, ovivcantidadentregada) VALUES (fila.far_ordenventaitemvalecc, fila.idcentroordenventaitemoriginal, fila.idcentroordenventaitemvale, fila.idordenventaitemoriginal, fila.idordenventaitemvale, fila.ovivcantidadentregada);
    END IF;
    RETURN fila;
    END;
    $function$
