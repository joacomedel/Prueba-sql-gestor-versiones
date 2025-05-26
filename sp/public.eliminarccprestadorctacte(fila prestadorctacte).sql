CREATE OR REPLACE FUNCTION public.eliminarccprestadorctacte(fila prestadorctacte)
 RETURNS prestadorctacte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadorctactecc:= current_timestamp;
    delete from sincro.prestadorctacte WHERE idprestadorctacte= fila.idprestadorctacte AND TRUE;
    RETURN fila;
    END;
    $function$
