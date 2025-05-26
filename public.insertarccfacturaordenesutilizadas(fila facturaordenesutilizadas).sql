CREATE OR REPLACE FUNCTION public.insertarccfacturaordenesutilizadas(fila facturaordenesutilizadas)
 RETURNS facturaordenesutilizadas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaordenesutilizadascc:= current_timestamp;
    UPDATE sincro.facturaordenesutilizadas SET anio= fila.anio, centro= fila.centro, facturaordenesutilizadascc= fila.facturaordenesutilizadascc, nroorden= fila.nroorden, nroregistro= fila.nroregistro, tipo= fila.tipo WHERE centro= fila.centro AND nroorden= fila.nroorden AND tipo= fila.tipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaordenesutilizadas(anio, centro, facturaordenesutilizadascc, nroorden, nroregistro, tipo) VALUES (fila.anio, fila.centro, fila.facturaordenesutilizadascc, fila.nroorden, fila.nroregistro, fila.tipo);
    END IF;
    RETURN fila;
    END;
    $function$
