CREATE OR REPLACE FUNCTION public.insertarccconsumoturismoestado(fila consumoturismoestado)
 RETURNS consumoturismoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumoturismoestadocc:= current_timestamp;
    UPDATE sincro.consumoturismoestado SET consumoturismoestadocc= fila.consumoturismoestadocc, ctefechafin= fila.ctefechafin, ctefechaini= fila.ctefechaini, idcentroconsumoturismo= fila.idcentroconsumoturismo, idcentroconsumoturismoestado= fila.idcentroconsumoturismoestado, idconsumoturismo= fila.idconsumoturismo, idconsumoturismoestado= fila.idconsumoturismoestado, idconsumoturismoestadotipos= fila.idconsumoturismoestadotipos WHERE idcentroconsumoturismoestado= fila.idcentroconsumoturismoestado AND idconsumoturismoestado= fila.idconsumoturismoestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.consumoturismoestado(consumoturismoestadocc, ctefechafin, ctefechaini, idcentroconsumoturismo, idcentroconsumoturismoestado, idconsumoturismo, idconsumoturismoestado, idconsumoturismoestadotipos) VALUES (fila.consumoturismoestadocc, fila.ctefechafin, fila.ctefechaini, fila.idcentroconsumoturismo, fila.idcentroconsumoturismoestado, fila.idconsumoturismo, fila.idconsumoturismoestado, fila.idconsumoturismoestadotipos);
    END IF;
    RETURN fila;
    END;
    $function$
