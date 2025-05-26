CREATE OR REPLACE FUNCTION public.insertarccconsumoturismovalores(fila consumoturismovalores)
 RETURNS consumoturismovalores
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumoturismovalorescc:= current_timestamp;
    UPDATE sincro.consumoturismovalores SET consumoturismovalorescc= fila.consumoturismovalorescc, ctvborrado= fila.ctvborrado, ctvcantdias= fila.ctvcantdias, fechaegreso= fila.fechaegreso, fechaingreso= fila.fechaingreso, idcentroconsumoturismo= fila.idcentroconsumoturismo, idconsumoturismo= fila.idconsumoturismo, idconsumoturismovalores= fila.idconsumoturismovalores, idturismounidadvalor= fila.idturismounidadvalor WHERE idcentroconsumoturismo= fila.idcentroconsumoturismo AND idconsumoturismo= fila.idconsumoturismo AND idconsumoturismovalores= fila.idconsumoturismovalores AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.consumoturismovalores(consumoturismovalorescc, ctvborrado, ctvcantdias, fechaegreso, fechaingreso, idcentroconsumoturismo, idconsumoturismo, idconsumoturismovalores, idturismounidadvalor) VALUES (fila.consumoturismovalorescc, fila.ctvborrado, fila.ctvcantdias, fila.fechaegreso, fila.fechaingreso, fila.idcentroconsumoturismo, fila.idconsumoturismo, fila.idconsumoturismovalores, fila.idturismounidadvalor);
    END IF;
    RETURN fila;
    END;
    $function$
