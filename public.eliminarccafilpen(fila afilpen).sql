CREATE OR REPLACE FUNCTION public.eliminarccafilpen(fila afilpen)
 RETURNS afilpen
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilpencc:= current_timestamp;
    delete from sincro.afilpen WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
