CREATE OR REPLACE FUNCTION public.eliminarcccuentacorrientepagos(fila cuentacorrientepagos)
 RETURNS cuentacorrientepagos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientepagoscc:= current_timestamp;
    delete from sincro.cuentacorrientepagos WHERE idcentropago= fila.idcentropago AND idpago= fila.idpago AND TRUE;
    RETURN fila;
    END;
    $function$
