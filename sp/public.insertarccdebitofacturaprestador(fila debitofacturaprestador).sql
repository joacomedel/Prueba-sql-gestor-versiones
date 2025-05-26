CREATE OR REPLACE FUNCTION public.insertarccdebitofacturaprestador(fila debitofacturaprestador)
 RETURNS debitofacturaprestador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.debitofacturaprestadorcc:= current_timestamp;
    UPDATE sincro.debitofacturaprestador SET anio= fila.anio, debitofacturaprestadorcc= fila.debitofacturaprestadorcc, fidtipoprestacion= fila.fidtipoprestacion, idcentrodebitofacturaprestador= fila.idcentrodebitofacturaprestador, iddebitofacturaprestador= fila.iddebitofacturaprestador, idmotivodebitofacturacion= fila.idmotivodebitofacturacion, importe= fila.importe, nroregistro= fila.nroregistro, observacion= fila.observacion WHERE idcentrodebitofacturaprestador= fila.idcentrodebitofacturaprestador AND iddebitofacturaprestador= fila.iddebitofacturaprestador AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.debitofacturaprestador(anio, debitofacturaprestadorcc, fidtipoprestacion, idcentrodebitofacturaprestador, iddebitofacturaprestador, idmotivodebitofacturacion, importe, nroregistro, observacion) VALUES (fila.anio, fila.debitofacturaprestadorcc, fila.fidtipoprestacion, fila.idcentrodebitofacturaprestador, fila.iddebitofacturaprestador, fila.idmotivodebitofacturacion, fila.importe, fila.nroregistro, fila.observacion);
    END IF;
    RETURN fila;
    END;
    $function$
