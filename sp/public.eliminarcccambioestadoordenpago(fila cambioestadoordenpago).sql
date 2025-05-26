CREATE OR REPLACE FUNCTION public.eliminarcccambioestadoordenpago(fila cambioestadoordenpago)
 RETURNS cambioestadoordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cambioestadoordenpagocc:= current_timestamp;
    delete from sincro.cambioestadoordenpago WHERE idcambioestado= fila.idcambioestado AND idcentrocambioestadoordenpago= fila.idcentrocambioestadoordenpago AND TRUE;
    RETURN fila;
    END;
    $function$
