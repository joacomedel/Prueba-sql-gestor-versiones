CREATE OR REPLACE FUNCTION public.eliminarccconsumoturismo(fila consumoturismo)
 RETURNS consumoturismo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumoturismocc:= current_timestamp;
    delete from sincro.consumoturismo WHERE idcentroconsumoturismo= fila.idcentroconsumoturismo AND idconsumoturismo= fila.idconsumoturismo AND TRUE;
    RETURN fila;
    END;
    $function$
