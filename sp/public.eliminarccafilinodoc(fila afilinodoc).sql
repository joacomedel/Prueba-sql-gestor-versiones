CREATE OR REPLACE FUNCTION public.eliminarccafilinodoc(fila afilinodoc)
 RETURNS afilinodoc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilinodoccc:= current_timestamp;
    delete from sincro.afilinodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
