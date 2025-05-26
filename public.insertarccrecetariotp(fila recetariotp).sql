CREATE OR REPLACE FUNCTION public.insertarccrecetariotp(fila recetariotp)
 RETURNS recetariotp
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariotpcc:= current_timestamp;
    UPDATE sincro.recetariotp SET cantidadauditada= fila.cantidadauditada, cantidademitida= fila.cantidademitida, centro= fila.centro, diagnostico= fila.diagnostico, idcentrofichamedica= fila.idcentrofichamedica, idcentrovalidacion= fila.idcentrovalidacion, idfichamedica= fila.idfichamedica, idusuario= fila.idusuario, idvalidacion= fila.idvalidacion, malcance= fila.malcance, mespecialidad= fila.mespecialidad, nromatricula= fila.nromatricula, nrorecetario= fila.nrorecetario, recetariotpcc= fila.recetariotpcc, rtpfechaauditoria= fila.rtpfechaauditoria, rtpfechavto= fila.rtpfechavto WHERE centro= fila.centro AND nrorecetario= fila.nrorecetario AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetariotp(cantidadauditada, cantidademitida, centro, diagnostico, idcentrofichamedica, idcentrovalidacion, idfichamedica, idusuario, idvalidacion, malcance, mespecialidad, nromatricula, nrorecetario, recetariotpcc, rtpfechaauditoria, rtpfechavto) VALUES (fila.cantidadauditada, fila.cantidademitida, fila.centro, fila.diagnostico, fila.idcentrofichamedica, fila.idcentrovalidacion, fila.idfichamedica, fila.idusuario, fila.idvalidacion, fila.malcance, fila.mespecialidad, fila.nromatricula, fila.nrorecetario, fila.recetariotpcc, fila.rtpfechaauditoria, fila.rtpfechavto);
    END IF;
    RETURN fila;
    END;
    $function$
