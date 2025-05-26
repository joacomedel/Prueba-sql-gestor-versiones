CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaitemvaleregalo(fila far_ordenventaitemvaleregalo)
 RETURNS far_ordenventaitemvaleregalo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemvaleregalocc:= current_timestamp;
    UPDATE sincro.far_ordenventaitemvaleregalo SET far_ordenventaitemvaleregalocc= fila.far_ordenventaitemvaleregalocc, idcentroordenventaitemvaleregalo= fila.idcentroordenventaitemvaleregalo, idordenventaitemoriginal= fila.idordenventaitemoriginal, idordenventaitemvaleregalo= fila.idordenventaitemvaleregalo, idcentroordenventaitemoriginal= fila.idcentroordenventaitemoriginal WHERE idordenventaitemoriginal= fila.idordenventaitemoriginal AND idordenventaitemvaleregalo= fila.idordenventaitemvaleregalo AND idcentroordenventaitemvaleregalo= fila.idcentroordenventaitemvaleregalo AND idcentroordenventaitemoriginal= fila.idcentroordenventaitemoriginal AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaitemvaleregalo(far_ordenventaitemvaleregalocc, idcentroordenventaitemvaleregalo, idordenventaitemoriginal, idordenventaitemvaleregalo, idcentroordenventaitemoriginal) VALUES (fila.far_ordenventaitemvaleregalocc, fila.idcentroordenventaitemvaleregalo, fila.idordenventaitemoriginal, fila.idordenventaitemvaleregalo, fila.idcentroordenventaitemoriginal);
    END IF;
    RETURN fila;
    END;
    $function$
