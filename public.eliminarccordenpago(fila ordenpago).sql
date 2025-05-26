CREATE OR REPLACE FUNCTION public.eliminarccordenpago(fila ordenpago)
 RETURNS ordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocc:= current_timestamp;
    delete from sincro.ordenpago WHERE nroordenpago= fila.nroordenpago AND idcentroordenpago= fila.idcentroordenpago AND TRUE;
    RETURN fila;
    END;
    $function$
