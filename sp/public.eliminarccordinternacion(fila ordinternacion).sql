CREATE OR REPLACE FUNCTION public.eliminarccordinternacion(fila ordinternacion)
 RETURNS ordinternacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordinternacioncc:= current_timestamp;
    delete from sincro.ordinternacion WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
