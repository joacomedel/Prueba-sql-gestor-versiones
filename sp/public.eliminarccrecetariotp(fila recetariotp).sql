CREATE OR REPLACE FUNCTION public.eliminarccrecetariotp(fila recetariotp)
 RETURNS recetariotp
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariotpcc:= current_timestamp;
    delete from sincro.recetariotp WHERE centro= fila.centro AND nrorecetario= fila.nrorecetario AND TRUE;
    RETURN fila;
    END;
    $function$
