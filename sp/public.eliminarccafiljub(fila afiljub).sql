CREATE OR REPLACE FUNCTION public.eliminarccafiljub(fila afiljub)
 RETURNS afiljub
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afiljubcc:= current_timestamp;
    delete from sincro.afiljub WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
