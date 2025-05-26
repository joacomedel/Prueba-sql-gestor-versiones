CREATE OR REPLACE FUNCTION public.eliminarccrecetarioestados(fila recetarioestados)
 RETURNS recetarioestados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetarioestadoscc:= current_timestamp;
    delete from sincro.recetarioestados WHERE idcentrorecetarioestado= fila.idcentrorecetarioestado AND idrecetarioestado= fila.idrecetarioestado AND TRUE;
    RETURN fila;
    END;
    $function$
