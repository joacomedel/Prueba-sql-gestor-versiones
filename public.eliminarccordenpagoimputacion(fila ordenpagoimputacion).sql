CREATE OR REPLACE FUNCTION public.eliminarccordenpagoimputacion(fila ordenpagoimputacion)
 RETURNS ordenpagoimputacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagoimputacioncc:= current_timestamp;
    delete from sincro.ordenpagoimputacion WHERE codigo= fila.codigo AND idcentroordenpago= fila.idcentroordenpago AND nroordenpago= fila.nroordenpago AND TRUE;
    RETURN fila;
    END;
    $function$
