CREATE OR REPLACE FUNCTION public.eliminarccprestamocuotas(fila prestamocuotas)
 RETURNS prestamocuotas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestamocuotascc:= current_timestamp;
    delete from sincro.prestamocuotas WHERE idprestamocuotas= fila.idprestamocuotas AND idcentroprestamocuota= fila.idcentroprestamocuota AND TRUE;
    RETURN fila;
    END;
    $function$
