CREATE OR REPLACE FUNCTION public.eliminarccverificacion(fila verificacion)
 RETURNS verificacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.verificacioncc:= current_timestamp;
    delete from sincro.verificacion WHERE codigo= fila.codigo AND fecha= fila.fecha AND nrodoc= fila.nrodoc AND TRUE;
    RETURN fila;
    END;
    $function$
