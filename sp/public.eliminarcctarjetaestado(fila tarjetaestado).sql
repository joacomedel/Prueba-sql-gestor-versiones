CREATE OR REPLACE FUNCTION public.eliminarcctarjetaestado(fila tarjetaestado)
 RETURNS tarjetaestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tarjetaestadocc:= current_timestamp;
    delete from sincro.tarjetaestado WHERE idcentrotarjeta= fila.idcentrotarjeta AND idcentrotarjetaestado= fila.idcentrotarjetaestado AND idtarjeta= fila.idtarjeta AND idtetcambioestado= fila.idtetcambioestado AND TRUE;
    RETURN fila;
    END;
    $function$
