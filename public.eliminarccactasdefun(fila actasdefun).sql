CREATE OR REPLACE FUNCTION public.eliminarccactasdefun(fila actasdefun)
 RETURNS actasdefun
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.actasdefuncc:= current_timestamp;
    delete from sincro.actasdefun WHERE tipodoc= fila.tipodoc AND nrodoc= fila.nrodoc AND TRUE;
    RETURN fila;
    END;
    $function$
