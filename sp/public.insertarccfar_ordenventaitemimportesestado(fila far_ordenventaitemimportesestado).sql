CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaitemimportesestado(fila far_ordenventaitemimportesestado)
 RETURNS far_ordenventaitemimportesestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemimportesestadocc:= current_timestamp;
    UPDATE sincro.far_ordenventaitemimportesestado SET far_ordenventaitemimportesestadocc= fila.far_ordenventaitemimportesestadocc, idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte, idcentroordenventaitemimportesestado= fila.idcentroordenventaitemimportesestado, idordenventaestadotipo= fila.idordenventaestadotipo, idordenventaitemimporte= fila.idordenventaitemimporte, idordenventaitemimportesaestado= fila.idordenventaitemimportesaestado, oveiiefechafin= fila.oveiiefechafin, oveiiefechaini= fila.oveiiefechaini, oviiedescripcion= fila.oviiedescripcion WHERE idcentroordenventaitemimportesestado= fila.idcentroordenventaitemimportesestado AND idordenventaitemimportesaestado= fila.idordenventaitemimportesaestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaitemimportesestado(far_ordenventaitemimportesestadocc, idcentroordenventaitemimporte, idcentroordenventaitemimportesestado, idordenventaestadotipo, idordenventaitemimporte, idordenventaitemimportesaestado, oveiiefechafin, oveiiefechaini, oviiedescripcion) VALUES (fila.far_ordenventaitemimportesestadocc, fila.idcentroordenventaitemimporte, fila.idcentroordenventaitemimportesestado, fila.idordenventaestadotipo, fila.idordenventaitemimporte, fila.idordenventaitemimportesaestado, fila.oveiiefechafin, fila.oveiiefechaini, fila.oviiedescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
