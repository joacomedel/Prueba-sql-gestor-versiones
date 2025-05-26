CREATE OR REPLACE FUNCTION public.eliminarccordenrecibo(fila ordenrecibo)
 RETURNS ordenrecibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenrecibocc:= current_timestamp;
    delete from sincro.ordenrecibo WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
