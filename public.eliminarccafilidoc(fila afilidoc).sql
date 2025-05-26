CREATE OR REPLACE FUNCTION public.eliminarccafilidoc(fila afilidoc)
 RETURNS afilidoc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilidoccc:= current_timestamp;
    delete from sincro.afilidoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
