CREATE OR REPLACE FUNCTION public.eliminarccplancobpersona(fila plancobpersona)
 RETURNS plancobpersona
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.plancobpersonacc:= current_timestamp;
    delete from sincro.plancobpersona WHERE idplancoberturas= fila.idplancoberturas AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
