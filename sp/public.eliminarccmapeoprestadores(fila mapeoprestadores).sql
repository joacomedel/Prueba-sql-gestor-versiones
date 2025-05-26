CREATE OR REPLACE FUNCTION public.eliminarccmapeoprestadores(fila mapeoprestadores)
 RETURNS mapeoprestadores
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.mapeoprestadorescc:= current_timestamp;
    delete from sincro.mapeoprestadores WHERE idprestadorsiges= fila.idprestadorsiges AND TRUE;
    RETURN fila;
    END;
    $function$
