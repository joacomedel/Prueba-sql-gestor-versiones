CREATE OR REPLACE FUNCTION public.eliminarccafilibec(fila afilibec)
 RETURNS afilibec
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilibeccc:= current_timestamp;
    delete from sincro.afilibec WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
