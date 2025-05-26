CREATE OR REPLACE FUNCTION public.insertarccfacturaprestaciones(fila facturaprestaciones)
 RETURNS facturaprestaciones
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaprestacionescc:= current_timestamp;
    UPDATE sincro.facturaprestaciones SET anio= fila.anio, debito= fila.debito, facturaprestacionescc= fila.facturaprestacionescc, fidtipoprestacion= fila.fidtipoprestacion, importe= fila.importe, nroregistro= fila.nroregistro, observacion= fila.observacion WHERE anio= fila.anio AND fidtipoprestacion= fila.fidtipoprestacion AND nroregistro= fila.nroregistro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaprestaciones(anio, debito, facturaprestacionescc, fidtipoprestacion, importe, nroregistro, observacion) VALUES (fila.anio, fila.debito, fila.facturaprestacionescc, fila.fidtipoprestacion, fila.importe, fila.nroregistro, fila.observacion);
    END IF;
    RETURN fila;
    END;
    $function$
