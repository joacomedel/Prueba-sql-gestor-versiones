CREATE OR REPLACE FUNCTION public.insertarccordenesutilizadas(fila ordenesutilizadas)
 RETURNS ordenesutilizadas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenesutilizadascc:= current_timestamp;
    UPDATE sincro.ordenesutilizadas SET centro= fila.centro, fechaauditoria= fila.fechaauditoria, fechauso= fila.fechauso, idosreci= fila.idosreci, idplancobertura= fila.idplancobertura, idprestador= fila.idprestador, importe= fila.importe, malcance= fila.malcance, mespecialidad= fila.mespecialidad, nrodocuso= fila.nrodocuso, nromatricula= fila.nromatricula, nroorden= fila.nroorden, ordenesutilizadascc= fila.ordenesutilizadascc, tipo= fila.tipo, tipodocuso= fila.tipodocuso WHERE centro= fila.centro AND nroorden= fila.nroorden AND tipo= fila.tipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenesutilizadas(centro, fechaauditoria, fechauso, idosreci, idplancobertura, idprestador, importe, malcance, mespecialidad, nrodocuso, nromatricula, nroorden, ordenesutilizadascc, tipo, tipodocuso) VALUES (fila.centro, fila.fechaauditoria, fila.fechauso, fila.idosreci, fila.idplancobertura, fila.idprestador, fila.importe, fila.malcance, fila.mespecialidad, fila.nrodocuso, fila.nromatricula, fila.nroorden, fila.ordenesutilizadascc, fila.tipo, fila.tipodocuso);
    END IF;
    RETURN fila;
    END;
    $function$
