CREATE OR REPLACE FUNCTION public.insertarcccupon(fila cupon)
 RETURNS cupon
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuponcc:= current_timestamp;
    UPDATE sincro.cupon SET cfechavto= fila.cfechavto, cuponcc= fila.cuponcc, idcentrocupon= fila.idcentrocupon, idcentrotarjeta= fila.idcentrotarjeta, idcupon= fila.idcupon, idtarjeta= fila.idtarjeta WHERE idcentrocupon= fila.idcentrocupon AND idcupon= fila.idcupon AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cupon(cfechavto, cuponcc, idcentrocupon, idcentrotarjeta, idcupon, idtarjeta) VALUES (fila.cfechavto, fila.cuponcc, fila.idcentrocupon, fila.idcentrotarjeta, fila.idcupon, fila.idtarjeta);
    END IF;
    RETURN fila;
    END;
    $function$
