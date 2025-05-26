CREATE OR REPLACE FUNCTION public.eliminarccprestador(fila prestador)
 RETURNS prestador
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadorcc:= current_timestamp;
    delete from sincro.prestador WHERE idprestador= fila.idprestador AND TRUE;
    RETURN fila;
    END;
    $function$
