CREATE OR REPLACE FUNCTION public.eliminarccaporterecibo(fila aporterecibo)
 RETURNS aporterecibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aporterecibocc:= current_timestamp;
    delete from sincro.aporterecibo WHERE idaporte= fila.idaporte AND idcentroregionaluso= fila.idcentroregionaluso AND TRUE;
    RETURN fila;
    END;
    $function$
