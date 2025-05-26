CREATE OR REPLACE FUNCTION public.insertarcctarjeta(fila tarjeta)
 RETURNS tarjeta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tarjetacc:= current_timestamp;
    UPDATE sincro.tarjeta SET idcentrotarjeta= fila.idcentrotarjeta, idtarjeta= fila.idtarjeta, nrodoc= fila.nrodoc, tarjetacc= fila.tarjetacc, tipodoc= fila.tipodoc WHERE idcentrotarjeta= fila.idcentrotarjeta AND idtarjeta= fila.idtarjeta AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.tarjeta(idcentrotarjeta, idtarjeta, nrodoc, tarjetacc, tipodoc) VALUES (fila.idcentrotarjeta, fila.idtarjeta, fila.nrodoc, fila.tarjetacc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
