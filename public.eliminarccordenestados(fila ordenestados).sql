CREATE OR REPLACE FUNCTION public.eliminarccordenestados(fila ordenestados)
 RETURNS ordenestados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenestadoscc:= current_timestamp;
    delete from sincro.ordenestados WHERE centro= fila.centro AND nroorden= fila.nroorden AND idordenestadotipos= fila.idordenestadotipos AND TRUE;
    RETURN fila;
    END;
    $function$
