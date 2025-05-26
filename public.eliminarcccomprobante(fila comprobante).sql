CREATE OR REPLACE FUNCTION public.eliminarcccomprobante(fila comprobante)
 RETURNS comprobante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.comprobantecc:= current_timestamp;
    delete from sincro.comprobante WHERE idcentroregional= fila.idcentroregional AND idcomprobante= fila.idcomprobante AND TRUE;
    RETURN fila;
    END;
    $function$
