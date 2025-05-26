CREATE OR REPLACE FUNCTION public.insertarccfestados(fila festados)
 RETURNS festados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.festadoscc:= current_timestamp;
    UPDATE sincro.festados SET fechacambio= fila.fechacambio, idcentrofestados= fila.idcentrofestados, festadoscc= fila.festadoscc, observacion= fila.observacion, tipoestadofactura= fila.tipoestadofactura, anio= fila.anio, idusuario= fila.idusuario, fidcambioestado= fila.fidcambioestado, fefechafin= fila.fefechafin, nroregistro= fila.nroregistro WHERE fidcambioestado= fila.fidcambioestado AND idcentrofestados= fila.idcentrofestados AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.festados(fechacambio, idcentrofestados, festadoscc, observacion, tipoestadofactura, anio, idusuario, fidcambioestado, fefechafin, nroregistro) VALUES (fila.fechacambio, fila.idcentrofestados, fila.festadoscc, fila.observacion, fila.tipoestadofactura, fila.anio, fila.idusuario, fila.fidcambioestado, fila.fefechafin, fila.nroregistro);
    END IF;
    RETURN fila;
    END;
    $function$
