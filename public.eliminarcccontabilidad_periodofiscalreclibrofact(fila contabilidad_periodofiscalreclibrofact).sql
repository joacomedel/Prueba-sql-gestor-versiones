CREATE OR REPLACE FUNCTION public.eliminarcccontabilidad_periodofiscalreclibrofact(fila contabilidad_periodofiscalreclibrofact)
 RETURNS contabilidad_periodofiscalreclibrofact
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.contabilidad_periodofiscalreclibrofactcc:= current_timestamp;
    delete from sincro.contabilidad_periodofiscalreclibrofact WHERE idrecepcion= fila.idrecepcion AND idperiodofiscal= fila.idperiodofiscal AND idcentroregional= fila.idcentroregional AND TRUE;
    RETURN fila;
    END;
    $function$
