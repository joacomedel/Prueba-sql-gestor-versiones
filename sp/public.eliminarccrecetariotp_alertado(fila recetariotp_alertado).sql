CREATE OR REPLACE FUNCTION public.eliminarccrecetariotp_alertado(fila recetariotp_alertado)
 RETURNS recetariotp_alertado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariotp_alertadocc:= current_timestamp;
    delete from sincro.recetariotp_alertado WHERE idcentrorecetariotpalertado= fila.idcentrorecetariotpalertado AND idrecetariotpalertado= fila.idrecetariotpalertado AND TRUE;
    RETURN fila;
    END;
    $function$
