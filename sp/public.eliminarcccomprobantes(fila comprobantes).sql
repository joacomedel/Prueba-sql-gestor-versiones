CREATE OR REPLACE FUNCTION public.eliminarcccomprobantes(fila comprobantes)
 RETURNS comprobantes
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.comprobantescc:= current_timestamp;
    delete from sincro.comprobantes WHERE idcentroregional= fila.idcentroregional AND idcomprobantes= fila.idcomprobantes AND TRUE;
    RETURN fila;
    END;
    $function$
