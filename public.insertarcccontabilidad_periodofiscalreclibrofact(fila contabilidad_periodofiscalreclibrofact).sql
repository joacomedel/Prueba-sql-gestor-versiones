CREATE OR REPLACE FUNCTION public.insertarcccontabilidad_periodofiscalreclibrofact(fila contabilidad_periodofiscalreclibrofact)
 RETURNS contabilidad_periodofiscalreclibrofact
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.contabilidad_periodofiscalreclibrofactcc:= current_timestamp;
    UPDATE sincro.contabilidad_periodofiscalreclibrofact SET contabilidad_periodofiscalreclibrofactcc= fila.contabilidad_periodofiscalreclibrofactcc, idrecepcion= fila.idrecepcion, idperiodofiscal= fila.idperiodofiscal, idcentroregional= fila.idcentroregional WHERE idrecepcion= fila.idrecepcion AND idperiodofiscal= fila.idperiodofiscal AND idcentroregional= fila.idcentroregional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.contabilidad_periodofiscalreclibrofact(contabilidad_periodofiscalreclibrofactcc, idrecepcion, idperiodofiscal, idcentroregional) VALUES (fila.contabilidad_periodofiscalreclibrofactcc, fila.idrecepcion, fila.idperiodofiscal, fila.idcentroregional);
    END IF;
    RETURN fila;
    END;
    $function$
