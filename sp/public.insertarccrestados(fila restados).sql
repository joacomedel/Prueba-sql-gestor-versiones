CREATE OR REPLACE FUNCTION public.insertarccrestados(fila restados)
 RETURNS restados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.restadoscc:= current_timestamp;
    UPDATE sincro.restados SET anio= fila.anio, fechacambio= fila.fechacambio, idcambioestado= fila.idcambioestado, idcentroregional= fila.idcentroregional, nroreintegro= fila.nroreintegro, observacion= fila.observacion, refechafin= fila.refechafin, restadoscc= fila.restadoscc, tipoestadoreintegro= fila.tipoestadoreintegro WHERE anio= fila.anio AND idcambioestado= fila.idcambioestado AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.restados(anio, fechacambio, idcambioestado, idcentroregional, nroreintegro, observacion, refechafin, restadoscc, tipoestadoreintegro) VALUES (fila.anio, fila.fechacambio, fila.idcambioestado, fila.idcentroregional, fila.nroreintegro, fila.observacion, fila.refechafin, fila.restadoscc, fila.tipoestadoreintegro);
    END IF;
    RETURN fila;
    END;
    $function$
