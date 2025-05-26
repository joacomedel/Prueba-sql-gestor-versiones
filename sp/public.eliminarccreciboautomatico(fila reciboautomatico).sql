CREATE OR REPLACE FUNCTION public.eliminarccreciboautomatico(fila reciboautomatico)
 RETURNS reciboautomatico
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reciboautomaticocc:= current_timestamp;
    delete from sincro.reciboautomatico WHERE centro= fila.centro AND idrecibo= fila.idrecibo AND TRUE;
    RETURN fila;
    END;
    $function$
