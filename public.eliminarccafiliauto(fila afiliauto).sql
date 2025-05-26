CREATE OR REPLACE FUNCTION public.eliminarccafiliauto(fila afiliauto)
 RETURNS afiliauto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afiliautocc:= current_timestamp;
    delete from sincro.afiliauto WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
