CREATE OR REPLACE FUNCTION public.eliminarccconsumoturismoestado(fila consumoturismoestado)
 RETURNS consumoturismoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumoturismoestadocc:= current_timestamp;
    delete from sincro.consumoturismoestado WHERE idcentroconsumoturismoestado= fila.idcentroconsumoturismoestado AND idconsumoturismoestado= fila.idconsumoturismoestado AND TRUE;
    RETURN fila;
    END;
    $function$
