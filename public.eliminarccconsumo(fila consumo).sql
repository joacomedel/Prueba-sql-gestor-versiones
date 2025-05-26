CREATE OR REPLACE FUNCTION public.eliminarccconsumo(fila consumo)
 RETURNS consumo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumocc:= current_timestamp;
    delete from sincro.consumo WHERE centro= fila.centro AND idconsumo= fila.idconsumo AND TRUE;
    RETURN fila;
    END;
    $function$
