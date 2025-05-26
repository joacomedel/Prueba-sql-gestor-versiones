CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaestado(fila far_ordenventaestado)
 RETURNS far_ordenventaestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaestadocc:= current_timestamp;
    UPDATE sincro.far_ordenventaestado SET far_ordenventaestadocc= fila.far_ordenventaestadocc, idcentroordenventa= fila.idcentroordenventa, idcentroordenventaestado= fila.idcentroordenventaestado, idordenventa= fila.idordenventa, idordenventaestado= fila.idordenventaestado, idordenventaestadotipo= fila.idordenventaestadotipo, ovefechafin= fila.ovefechafin, ovefechaini= fila.ovefechaini, oveidusuario= fila.oveidusuario WHERE idordenventaestado= fila.idordenventaestado AND idcentroordenventaestado= fila.idcentroordenventaestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaestado(far_ordenventaestadocc, idcentroordenventa, idcentroordenventaestado, idordenventa, idordenventaestado, idordenventaestadotipo, ovefechafin, ovefechaini, oveidusuario) VALUES (fila.far_ordenventaestadocc, fila.idcentroordenventa, fila.idcentroordenventaestado, fila.idordenventa, fila.idordenventaestado, fila.idordenventaestadotipo, fila.ovefechafin, fila.ovefechaini, fila.oveidusuario);
    END IF;
    RETURN fila;
    END;
    $function$
