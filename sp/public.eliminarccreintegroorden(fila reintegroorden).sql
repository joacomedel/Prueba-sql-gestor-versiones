CREATE OR REPLACE FUNCTION public.eliminarccreintegroorden(fila reintegroorden)
 RETURNS reintegroorden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegroordencc:= current_timestamp;
    delete from sincro.reintegroorden WHERE centro= fila.centro AND nroorden= fila.nroorden AND tipo= fila.tipo AND TRUE;
    RETURN fila;
    END;
    $function$
