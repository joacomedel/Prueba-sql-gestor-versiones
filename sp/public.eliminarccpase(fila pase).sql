CREATE OR REPLACE FUNCTION public.eliminarccpase(fila pase)
 RETURNS pase
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pasecc:= current_timestamp;
    delete from sincro.pase WHERE idpase= fila.idpase AND idcentropase= fila.idcentropase AND TRUE;
    RETURN fila;
    END;
    $function$
