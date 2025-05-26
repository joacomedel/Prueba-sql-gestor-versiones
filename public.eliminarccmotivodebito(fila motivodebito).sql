CREATE OR REPLACE FUNCTION public.eliminarccmotivodebito(fila motivodebito)
 RETURNS motivodebito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.motivodebitocc:= current_timestamp;
    delete from sincro.motivodebito WHERE idmotivodebito= fila.idmotivodebito AND TRUE;
    RETURN fila;
    END;
    $function$
