CREATE OR REPLACE FUNCTION public.eliminarccusuarioconfiguracion(fila usuarioconfiguracion)
 RETURNS usuarioconfiguracion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.usuarioconfiguracioncc:= current_timestamp;
    delete from sincro.usuarioconfiguracion WHERE dni= fila.dni AND TRUE;
    RETURN fila;
    END;
    $function$
