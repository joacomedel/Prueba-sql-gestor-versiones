CREATE OR REPLACE FUNCTION public.insertarccordenreciprocidadpreauditada(fila ordenreciprocidadpreauditada)
 RETURNS ordenreciprocidadpreauditada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenreciprocidadpreauditadacc:= current_timestamp;
    UPDATE sincro.ordenreciprocidadpreauditada SET anio= fila.anio, barra= fila.barra, centro= fila.centro, idcentroorpreauditada= fila.idcentroorpreauditada, idcomprobantetipos= fila.idcomprobantetipos, idordenreciprocidadpreauditada= fila.idordenreciprocidadpreauditada, idosreci= fila.idosreci, nroorden= fila.nroorden, nroregistro= fila.nroregistro, ordenreciprocidadpreauditadacc= fila.ordenreciprocidadpreauditadacc WHERE anio= fila.anio AND centro= fila.centro AND idcomprobantetipos= fila.idcomprobantetipos AND nroorden= fila.nroorden AND nroregistro= fila.nroregistro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenreciprocidadpreauditada(anio, barra, centro, idcentroorpreauditada, idcomprobantetipos, idordenreciprocidadpreauditada, idosreci, nroorden, nroregistro, ordenreciprocidadpreauditadacc) VALUES (fila.anio, fila.barra, fila.centro, fila.idcentroorpreauditada, fila.idcomprobantetipos, fila.idordenreciprocidadpreauditada, fila.idosreci, fila.nroorden, fila.nroregistro, fila.ordenreciprocidadpreauditadacc);
    END IF;
    RETURN fila;
    END;
    $function$
