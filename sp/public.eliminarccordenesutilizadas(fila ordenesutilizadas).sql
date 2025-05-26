CREATE OR REPLACE FUNCTION public.eliminarccordenesutilizadas(fila ordenesutilizadas)
 RETURNS ordenesutilizadas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenesutilizadascc:= current_timestamp;
    delete from sincro.ordenesutilizadas WHERE centro= fila.centro AND nroorden= fila.nroorden AND tipo= fila.tipo AND TRUE;
    RETURN fila;
    END;
    $function$
