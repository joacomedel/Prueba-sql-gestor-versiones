CREATE OR REPLACE FUNCTION public.eliminarccresolbec(fila resolbec)
 RETURNS resolbec
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.resolbeccc:= current_timestamp;
    delete from sincro.resolbec WHERE idresolbe= fila.idresolbe AND TRUE;
    RETURN fila;
    END;
    $function$
