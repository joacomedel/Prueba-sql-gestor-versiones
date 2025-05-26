CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaitemestado(fila far_ordenventaitemestado)
 RETURNS far_ordenventaitemestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemestadocc:= current_timestamp;
    UPDATE sincro.far_ordenventaitemestado SET far_ordenventaitemestadocc= fila.far_ordenventaitemestadocc, idcentroordenventaitem= fila.idcentroordenventaitem, idcentroordenventaitemestado= fila.idcentroordenventaitemestado, idordenventaestadotipo= fila.idordenventaestadotipo, idordenventaitem= fila.idordenventaitem, idordenventaitemaestado= fila.idordenventaitemaestado, oveiefechafin= fila.oveiefechafin, oveiefechaini= fila.oveiefechaini, oviedescripcion= fila.oviedescripcion WHERE idcentroordenventaitemestado= fila.idcentroordenventaitemestado AND idordenventaitemaestado= fila.idordenventaitemaestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaitemestado(far_ordenventaitemestadocc, idcentroordenventaitem, idcentroordenventaitemestado, idordenventaestadotipo, idordenventaitem, idordenventaitemaestado, oveiefechafin, oveiefechaini, oviedescripcion) VALUES (fila.far_ordenventaitemestadocc, fila.idcentroordenventaitem, fila.idcentroordenventaitemestado, fila.idordenventaestadotipo, fila.idordenventaitem, fila.idordenventaitemaestado, fila.oveiefechafin, fila.oveiefechaini, fila.oviedescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
