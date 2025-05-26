CREATE OR REPLACE FUNCTION public.insertarccrecetarioitemestado(fila recetarioitemestado)
 RETURNS recetarioitemestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetarioitemestadocc:= current_timestamp;
    UPDATE sincro.recetarioitemestado SET idrecetarioitemestado= fila.idrecetarioitemestado, riefechaini= fila.riefechaini, idtipocambioestado= fila.idtipocambioestado, riedescripcion= fila.riedescripcion, idcentrorecetarioitemestado= fila.idcentrorecetarioitemestado, recetarioitemestadocc= fila.recetarioitemestadocc, riefechafin= fila.riefechafin, idrecetarioitem= fila.idrecetarioitem, idcentrorecetarioitem= fila.idcentrorecetarioitem WHERE idrecetarioitemestado= fila.idrecetarioitemestado AND idcentrorecetarioitemestado= fila.idcentrorecetarioitemestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetarioitemestado(idrecetarioitemestado, riefechaini, idtipocambioestado, riedescripcion, idcentrorecetarioitemestado, recetarioitemestadocc, riefechafin, idrecetarioitem, idcentrorecetarioitem) VALUES (fila.idrecetarioitemestado, fila.riefechaini, fila.idtipocambioestado, fila.riedescripcion, fila.idcentrorecetarioitemestado, fila.recetarioitemestadocc, fila.riefechafin, fila.idrecetarioitem, fila.idcentrorecetarioitem);
    END IF;
    RETURN fila;
    END;
    $function$
