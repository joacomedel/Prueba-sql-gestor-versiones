CREATE OR REPLACE FUNCTION public.eliminarccbenefsosunc(fila benefsosunc)
 RETURNS benefsosunc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.benefsosunccc:= current_timestamp;
    delete from sincro.benefsosunc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
