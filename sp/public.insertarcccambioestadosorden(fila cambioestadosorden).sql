CREATE OR REPLACE FUNCTION public.insertarcccambioestadosorden(fila cambioestadosorden)
 RETURNS cambioestadosorden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cambioestadosordencc:= current_timestamp;
    UPDATE sincro.cambioestadosorden SET cambioestadosordencc= fila.cambioestadosordencc, centro= fila.centro, ceofechafin= fila.ceofechafin, ceofechaini= fila.ceofechaini, ceoidusuario= fila.ceoidusuario, idcambioestadosorden= fila.idcambioestadosorden, idcentrocambioestadosorden= fila.idcentrocambioestadosorden, idordenventaestadotipo= fila.idordenventaestadotipo, nroorden= fila.nroorden, observacion= fila.observacion WHERE idcambioestadosorden= fila.idcambioestadosorden AND idcentrocambioestadosorden= fila.idcentrocambioestadosorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cambioestadosorden(cambioestadosordencc, centro, ceofechafin, ceofechaini, ceoidusuario, idcambioestadosorden, idcentrocambioestadosorden, idordenventaestadotipo, nroorden, observacion) VALUES (fila.cambioestadosordencc, fila.centro, fila.ceofechafin, fila.ceofechaini, fila.ceoidusuario, fila.idcambioestadosorden, fila.idcentrocambioestadosorden, fila.idordenventaestadotipo, fila.nroorden, fila.observacion);
    END IF;
    RETURN fila;
    END;
    $function$
