CREATE OR REPLACE FUNCTION public.eliminarccconsumoturismovalores(fila consumoturismovalores)
 RETURNS consumoturismovalores
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumoturismovalorescc:= current_timestamp;
    delete from sincro.consumoturismovalores WHERE idcentroconsumoturismo= fila.idcentroconsumoturismo AND idconsumoturismo= fila.idconsumoturismo AND idconsumoturismovalores= fila.idconsumoturismovalores AND TRUE;
    RETURN fila;
    END;
    $function$
