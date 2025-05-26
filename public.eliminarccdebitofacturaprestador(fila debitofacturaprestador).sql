CREATE OR REPLACE FUNCTION public.eliminarccdebitofacturaprestador(fila debitofacturaprestador)
 RETURNS debitofacturaprestador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.debitofacturaprestadorcc:= current_timestamp;
    delete from sincro.debitofacturaprestador WHERE idcentrodebitofacturaprestador= fila.idcentrodebitofacturaprestador AND iddebitofacturaprestador= fila.iddebitofacturaprestador AND TRUE;
    RETURN fila;
    END;
    $function$
