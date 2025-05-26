CREATE OR REPLACE FUNCTION public.eliminarccrecetarioitemestado(fila recetarioitemestado)
 RETURNS recetarioitemestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetarioitemestadocc:= current_timestamp;
    delete from sincro.recetarioitemestado WHERE idrecetarioitemestado= fila.idrecetarioitemestado AND idcentrorecetarioitemestado= fila.idcentrorecetarioitemestado AND TRUE;
    RETURN fila;
    END;
    $function$
