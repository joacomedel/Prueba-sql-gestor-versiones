CREATE OR REPLACE FUNCTION public.insertarccrecetariotp_alertado(fila recetariotp_alertado)
 RETURNS recetariotp_alertado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariotp_alertadocc:= current_timestamp;
    UPDATE sincro.recetariotp_alertado SET centro= fila.centro, idcentrorecetariotpalertado= fila.idcentrorecetariotpalertado, idcentrorecetariotpitem= fila.idcentrorecetariotpitem, idrecetariotpalertado= fila.idrecetariotpalertado, idrecetariotpitem= fila.idrecetariotpitem, idusuariocreacion= fila.idusuariocreacion, nrorecetario= fila.nrorecetario, rafechafin= fila.rafechafin, rafechainicio= fila.rafechainicio, raobservacion= fila.raobservacion, recetariotp_alertadocc= fila.recetariotp_alertadocc WHERE idcentrorecetariotpalertado= fila.idcentrorecetariotpalertado AND idrecetariotpalertado= fila.idrecetariotpalertado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetariotp_alertado(centro, idcentrorecetariotpalertado, idcentrorecetariotpitem, idrecetariotpalertado, idrecetariotpitem, idusuariocreacion, nrorecetario, rafechafin, rafechainicio, raobservacion, recetariotp_alertadocc) VALUES (fila.centro, fila.idcentrorecetariotpalertado, fila.idcentrorecetariotpitem, fila.idrecetariotpalertado, fila.idrecetariotpitem, fila.idusuariocreacion, fila.nrorecetario, fila.rafechafin, fila.rafechainicio, fila.raobservacion, fila.recetariotp_alertadocc);
    END IF;
    RETURN fila;
    END;
    $function$
