CREATE OR REPLACE FUNCTION public.eliminarccrecetario(fila recetario)
 RETURNS recetario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariocc:= current_timestamp;
    delete from sincro.recetario WHERE centro= fila.centro AND nrorecetario= fila.nrorecetario AND TRUE;
    RETURN fila;
    END;
    $function$
