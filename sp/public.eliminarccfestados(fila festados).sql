CREATE OR REPLACE FUNCTION public.eliminarccfestados(fila festados)
 RETURNS festados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.festadoscc:= current_timestamp;
    delete from sincro.festados WHERE fidcambioestado= fila.fidcambioestado AND idcentrofestados= fila.idcentrofestados AND TRUE;
    RETURN fila;
    END;
    $function$
