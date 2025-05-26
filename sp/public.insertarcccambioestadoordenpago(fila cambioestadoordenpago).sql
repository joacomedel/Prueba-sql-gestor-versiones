CREATE OR REPLACE FUNCTION public.insertarcccambioestadoordenpago(fila cambioestadoordenpago)
 RETURNS cambioestadoordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cambioestadoordenpagocc:= current_timestamp;
    UPDATE sincro.cambioestadoordenpago SET fechacambio= fila.fechacambio, ceopfechafin= fila.ceopfechafin, motivo= fila.motivo, idcentroordenpago= fila.idcentroordenpago, idcentrocambioestadoordenpago= fila.idcentrocambioestadoordenpago, idtipoestadoordenpago= fila.idtipoestadoordenpago, cambioestadoordenpagocc= fila.cambioestadoordenpagocc, idusuario= fila.idusuario, idcambioestado= fila.idcambioestado, nroordenpago= fila.nroordenpago WHERE idcambioestado= fila.idcambioestado AND idcentrocambioestadoordenpago= fila.idcentrocambioestadoordenpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cambioestadoordenpago(fechacambio, ceopfechafin, motivo, idcentroordenpago, idcentrocambioestadoordenpago, idtipoestadoordenpago, cambioestadoordenpagocc, idusuario, idcambioestado, nroordenpago) VALUES (fila.fechacambio, fila.ceopfechafin, fila.motivo, fila.idcentroordenpago, fila.idcentrocambioestadoordenpago, fila.idtipoestadoordenpago, fila.cambioestadoordenpagocc, fila.idusuario, fila.idcambioestado, fila.nroordenpago);
    END IF;
    RETURN fila;
    END;
    $function$
