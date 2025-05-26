CREATE OR REPLACE FUNCTION public.eliminarccafilreci(fila afilreci)
 RETURNS afilreci
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilrecicc:= current_timestamp;
    delete from sincro.afilreci WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
