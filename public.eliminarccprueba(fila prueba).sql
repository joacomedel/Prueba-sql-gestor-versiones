CREATE OR REPLACE FUNCTION public.eliminarccprueba(fila prueba)
 RETURNS prueba
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pruebacc:= current_timestamp;
    delete from sincro.prueba WHERE tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
