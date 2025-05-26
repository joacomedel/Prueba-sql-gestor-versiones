CREATE OR REPLACE FUNCTION public.eliminarccafilsosunc(fila afilsosunc)
 RETURNS afilsosunc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilsosunccc:= current_timestamp;
    delete from sincro.afilsosunc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
