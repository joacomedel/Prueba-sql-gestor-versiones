CREATE OR REPLACE FUNCTION public.eliminarcctarjeta(fila tarjeta)
 RETURNS tarjeta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tarjetacc:= current_timestamp;
    delete from sincro.tarjeta WHERE idcentrotarjeta= fila.idcentrotarjeta AND idtarjeta= fila.idtarjeta AND TRUE;
    RETURN fila;
    END;
    $function$
