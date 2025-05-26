CREATE OR REPLACE FUNCTION public.eliminarccaporte(fila aporte)
 RETURNS aporte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aportecc:= current_timestamp;
    delete from sincro.aporte WHERE idaporte= fila.idaporte AND idcentroregionaluso= fila.idcentroregionaluso AND TRUE;
    RETURN fila;
    END;
    $function$
