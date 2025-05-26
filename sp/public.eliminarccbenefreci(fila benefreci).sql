CREATE OR REPLACE FUNCTION public.eliminarccbenefreci(fila benefreci)
 RETURNS benefreci
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.benefrecicc:= current_timestamp;
    delete from sincro.benefreci WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
