CREATE OR REPLACE FUNCTION public.eliminarccaporteestado(fila aporteestado)
 RETURNS aporteestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aporteestadocc:= current_timestamp;
    delete from sincro.aporteestado WHERE idaporteestado= fila.idaporteestado AND idcentroaporteestado= fila.idcentroaporteestado AND TRUE;
    RETURN fila;
    END;
    $function$
