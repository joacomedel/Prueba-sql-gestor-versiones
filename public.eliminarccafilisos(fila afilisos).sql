CREATE OR REPLACE FUNCTION public.eliminarccafilisos(fila afilisos)
 RETURNS afilisos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilisoscc:= current_timestamp;
    delete from sincro.afilisos WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
