CREATE OR REPLACE FUNCTION public.eliminarccprestadorconfig(fila prestadorconfig)
 RETURNS prestadorconfig
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadorconfigcc:= current_timestamp;
    delete from sincro.prestadorconfig WHERE idprestadorconfig= fila.idprestadorconfig AND idcentroprestadorconfig= fila.idcentroprestadorconfig AND TRUE;
    RETURN fila;
    END;
    $function$
