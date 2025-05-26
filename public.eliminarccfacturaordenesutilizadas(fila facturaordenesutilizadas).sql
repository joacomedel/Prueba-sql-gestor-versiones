CREATE OR REPLACE FUNCTION public.eliminarccfacturaordenesutilizadas(fila facturaordenesutilizadas)
 RETURNS facturaordenesutilizadas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaordenesutilizadascc:= current_timestamp;
    delete from sincro.facturaordenesutilizadas WHERE centro= fila.centro AND nroorden= fila.nroorden AND tipo= fila.tipo AND TRUE;
    RETURN fila;
    END;
    $function$
