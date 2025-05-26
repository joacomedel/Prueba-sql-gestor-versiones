CREATE OR REPLACE FUNCTION public.eliminarccrecibo(fila recibo)
 RETURNS recibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibocc:= current_timestamp;
    delete from sincro.recibo WHERE idrecibo= fila.idrecibo AND centro= fila.centro AND TRUE;
    RETURN fila;
    END;
    $function$
