CREATE OR REPLACE FUNCTION public.eliminarccrecibousuario(fila recibousuario)
 RETURNS recibousuario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibousuariocc:= current_timestamp;
    delete from sincro.recibousuario WHERE centro= fila.centro AND idrecibo= fila.idrecibo AND TRUE;
    RETURN fila;
    END;
    $function$
