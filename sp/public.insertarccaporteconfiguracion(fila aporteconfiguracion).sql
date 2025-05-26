CREATE OR REPLACE FUNCTION public.insertarccaporteconfiguracion(fila aporteconfiguracion)
 RETURNS aporteconfiguracion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aporteconfiguracioncc:= current_timestamp;
    UPDATE sincro.aporteconfiguracion SET nrodoc= fila.nrodoc, aporteconfiguracioncc= fila.aporteconfiguracioncc, acporcentaje= fila.acporcentaje, idaporteconfiguracion= fila.idaporteconfiguracion, acfechainicio= fila.acfechainicio, tipodoc= fila.tipodoc, acfechafin= fila.acfechafin, descripcion= fila.descripcion, idcentroaporteconfiguracion= fila.idcentroaporteconfiguracion, acimportebruto= fila.acimportebruto, acimporteaporte= fila.acimporteaporte WHERE idcentroaporteconfiguracion= fila.idcentroaporteconfiguracion AND idaporteconfiguracion= fila.idaporteconfiguracion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.aporteconfiguracion(nrodoc, aporteconfiguracioncc, acporcentaje, idaporteconfiguracion, acfechainicio, tipodoc, acfechafin, descripcion, idcentroaporteconfiguracion, acimportebruto, acimporteaporte) VALUES (fila.nrodoc, fila.aporteconfiguracioncc, fila.acporcentaje, fila.idaporteconfiguracion, fila.acfechainicio, fila.tipodoc, fila.acfechafin, fila.descripcion, fila.idcentroaporteconfiguracion, fila.acimportebruto, fila.acimporteaporte);
    END IF;
    RETURN fila;
    END;
    $function$
