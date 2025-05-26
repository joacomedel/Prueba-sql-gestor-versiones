CREATE OR REPLACE FUNCTION public.eliminarcctamanos(fila tamanos)
 RETURNS tamanos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tamanoscc:= current_timestamp;
    delete from sincro.tamanos WHERE idtamanos= fila.idtamanos AND TRUE;
    RETURN fila;
    END;
    $function$
