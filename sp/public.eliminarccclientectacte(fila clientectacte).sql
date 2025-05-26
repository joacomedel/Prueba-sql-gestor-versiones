CREATE OR REPLACE FUNCTION public.eliminarccclientectacte(fila clientectacte)
 RETURNS clientectacte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.clientectactecc:= current_timestamp;
    delete from sincro.clientectacte WHERE idclientectacte= fila.idclientectacte AND idcentroclientectacte= fila.idcentroclientectacte AND TRUE;
    RETURN fila;
    END;
    $function$
