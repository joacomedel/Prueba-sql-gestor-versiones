CREATE OR REPLACE FUNCTION public.eliminarccusuario(fila usuario)
 RETURNS usuario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.usuariocc:= current_timestamp;
    delete from sincro.usuario WHERE contrasena= fila.contrasena AND dni= fila.dni AND idcentroregional= fila.idcentroregional AND TRUE;
    RETURN fila;
    END;
    $function$
