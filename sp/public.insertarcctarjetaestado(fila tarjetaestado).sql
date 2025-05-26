CREATE OR REPLACE FUNCTION public.insertarcctarjetaestado(fila tarjetaestado)
 RETURNS tarjetaestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tarjetaestadocc:= current_timestamp;
    UPDATE sincro.tarjetaestado SET idcentrotarjeta= fila.idcentrotarjeta, idcentrotarjetaestado= fila.idcentrotarjetaestado, idestadotipo= fila.idestadotipo, idtarjeta= fila.idtarjeta, idtetcambioestado= fila.idtetcambioestado, tarjetaestadocc= fila.tarjetaestadocc, tefechafin= fila.tefechafin, tefechaini= fila.tefechaini WHERE idcentrotarjeta= fila.idcentrotarjeta AND idcentrotarjetaestado= fila.idcentrotarjetaestado AND idtarjeta= fila.idtarjeta AND idtetcambioestado= fila.idtetcambioestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.tarjetaestado(idcentrotarjeta, idcentrotarjetaestado, idestadotipo, idtarjeta, idtetcambioestado, tarjetaestadocc, tefechafin, tefechaini) VALUES (fila.idcentrotarjeta, fila.idcentrotarjetaestado, fila.idestadotipo, fila.idtarjeta, fila.idtetcambioestado, fila.tarjetaestadocc, fila.tefechafin, fila.tefechaini);
    END IF;
    RETURN fila;
    END;
    $function$
