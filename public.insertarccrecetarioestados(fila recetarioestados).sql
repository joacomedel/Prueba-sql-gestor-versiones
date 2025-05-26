CREATE OR REPLACE FUNCTION public.insertarccrecetarioestados(fila recetarioestados)
 RETURNS recetarioestados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetarioestadoscc:= current_timestamp;
    UPDATE sincro.recetarioestados SET centro= fila.centro, idcentrorecetarioestado= fila.idcentrorecetarioestado, idrecetarioestado= fila.idrecetarioestado, idtipocambioestado= fila.idtipocambioestado, nrorecetario= fila.nrorecetario, recetarioestadoscc= fila.recetarioestadoscc, redescripcion= fila.redescripcion, refechafin= fila.refechafin, refechamodificacion= fila.refechamodificacion WHERE idcentrorecetarioestado= fila.idcentrorecetarioestado AND idrecetarioestado= fila.idrecetarioestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetarioestados(centro, idcentrorecetarioestado, idrecetarioestado, idtipocambioestado, nrorecetario, recetarioestadoscc, redescripcion, refechafin, refechamodificacion) VALUES (fila.centro, fila.idcentrorecetarioestado, fila.idrecetarioestado, fila.idtipocambioestado, fila.nrorecetario, fila.recetarioestadoscc, fila.redescripcion, fila.refechafin, fila.refechamodificacion);
    END IF;
    RETURN fila;
    END;
    $function$
