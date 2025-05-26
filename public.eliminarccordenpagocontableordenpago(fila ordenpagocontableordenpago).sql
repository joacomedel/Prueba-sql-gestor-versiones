CREATE OR REPLACE FUNCTION public.eliminarccordenpagocontableordenpago(fila ordenpagocontableordenpago)
 RETURNS ordenpagocontableordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocontableordenpagocc:= current_timestamp;
    delete from sincro.ordenpagocontableordenpago WHERE idordenpagocontable= fila.idordenpagocontable AND idcentroordenpago= fila.idcentroordenpago AND idcentroordenpagocontable= fila.idcentroordenpagocontable AND nroordenpago= fila.nroordenpago AND TRUE;
    RETURN fila;
    END;
    $function$
