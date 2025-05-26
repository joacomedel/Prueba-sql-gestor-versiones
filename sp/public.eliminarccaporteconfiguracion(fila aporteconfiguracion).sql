CREATE OR REPLACE FUNCTION public.eliminarccaporteconfiguracion(fila aporteconfiguracion)
 RETURNS aporteconfiguracion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aporteconfiguracioncc:= current_timestamp;
    delete from sincro.aporteconfiguracion WHERE idcentroaporteconfiguracion= fila.idcentroaporteconfiguracion AND idaporteconfiguracion= fila.idaporteconfiguracion AND TRUE;
    RETURN fila;
    END;
    $function$
