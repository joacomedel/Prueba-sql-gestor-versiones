CREATE OR REPLACE FUNCTION public.eliminarccpersona(fila persona)
 RETURNS persona
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.personacc:= current_timestamp;
    delete from sincro.persona WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
