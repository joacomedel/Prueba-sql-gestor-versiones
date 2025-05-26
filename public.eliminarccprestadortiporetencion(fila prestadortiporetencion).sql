CREATE OR REPLACE FUNCTION public.eliminarccprestadortiporetencion(fila prestadortiporetencion)
 RETURNS prestadortiporetencion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadortiporetencioncc:= current_timestamp;
    delete from sincro.prestadortiporetencion WHERE idprestador= fila.idprestador AND idtiporetencion= fila.idtiporetencion AND TRUE;
    RETURN fila;
    END;
    $function$
