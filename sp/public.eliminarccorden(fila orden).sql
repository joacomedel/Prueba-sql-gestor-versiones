CREATE OR REPLACE FUNCTION public.eliminarccorden(fila orden)
 RETURNS orden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordencc:= current_timestamp;
    delete from sincro.orden WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
