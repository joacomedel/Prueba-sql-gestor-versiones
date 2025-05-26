CREATE OR REPLACE FUNCTION public.eliminarccimportesorden(fila importesorden)
 RETURNS importesorden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.importesordencc:= current_timestamp;
    delete from sincro.importesorden WHERE centro= fila.centro AND idformapagotipos= fila.idformapagotipos AND nroorden= fila.nroorden AND TRUE;
    RETURN fila;
    END;
    $function$
