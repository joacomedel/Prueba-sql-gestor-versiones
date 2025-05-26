CREATE OR REPLACE FUNCTION public.eliminarcccondicioniva(fila condicioniva)
 RETURNS condicioniva
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.condicionivacc:= current_timestamp;
    delete from sincro.condicioniva WHERE idcondicioniva= fila.idcondicioniva AND TRUE;
    RETURN fila;
    END;
    $function$
