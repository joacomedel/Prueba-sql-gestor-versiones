CREATE OR REPLACE FUNCTION public.insertarcciteminformacion(fila iteminformacion)
 RETURNS iteminformacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.iteminformacioncc:= current_timestamp;
    UPDATE sincro.iteminformacion SET centro= fila.centro, idconfiguracion= fila.idconfiguracion, iditem= fila.iditem, iditemestadotipo= fila.iditemestadotipo, iicoberturaamuc= fila.iicoberturaamuc, iicoberturasosuncauditada= fila.iicoberturasosuncauditada, iicoberturasosuncexpendida= fila.iicoberturasosuncexpendida, iicoberturasosuncsugerida= fila.iicoberturasosuncsugerida, iicomentario= fila.iicomentario, iierror= fila.iierror, iifechaauditoria= fila.iifechaauditoria, iiimporteafiliadounitario= fila.iiimporteafiliadounitario, iiimporteamucunitario= fila.iiimporteamucunitario, iiimportesosuncunitario= fila.iiimportesosuncunitario, iiimporteunitario= fila.iiimporteunitario, iiobservacion= fila.iiobservacion, iteminformacioncc= fila.iteminformacioncc WHERE centro= fila.centro AND iditem= fila.iditem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.iteminformacion(centro, idconfiguracion, iditem, iditemestadotipo, iicoberturaamuc, iicoberturasosuncauditada, iicoberturasosuncexpendida, iicoberturasosuncsugerida, iicomentario, iierror, iifechaauditoria, iiimporteafiliadounitario, iiimporteamucunitario, iiimportesosuncunitario, iiimporteunitario, iiobservacion, iteminformacioncc) VALUES (fila.centro, fila.idconfiguracion, fila.iditem, fila.iditemestadotipo, fila.iicoberturaamuc, fila.iicoberturasosuncauditada, fila.iicoberturasosuncexpendida, fila.iicoberturasosuncsugerida, fila.iicomentario, fila.iierror, fila.iifechaauditoria, fila.iiimporteafiliadounitario, fila.iiimporteamucunitario, fila.iiimportesosuncunitario, fila.iiimporteunitario, fila.iiobservacion, fila.iteminformacioncc);
    END IF;
    RETURN fila;
    END;
    $function$
