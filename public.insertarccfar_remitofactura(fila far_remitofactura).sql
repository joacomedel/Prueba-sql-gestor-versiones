CREATE OR REPLACE FUNCTION public.insertarccfar_remitofactura(fila far_remitofactura)
 RETURNS far_remitofactura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitofacturacc:= current_timestamp;
    UPDATE sincro.far_remitofactura SET anio= fila.anio, centro= fila.centro, far_remitofacturacc= fila.far_remitofacturacc, idremito= fila.idremito, nroregistro= fila.nroregistro WHERE anio= fila.anio AND centro= fila.centro AND idremito= fila.idremito AND nroregistro= fila.nroregistro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_remitofactura(anio, centro, far_remitofacturacc, idremito, nroregistro) VALUES (fila.anio, fila.centro, fila.far_remitofacturacc, fila.idremito, fila.nroregistro);
    END IF;
    RETURN fila;
    END;
    $function$
