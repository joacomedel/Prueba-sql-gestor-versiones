CREATE OR REPLACE FUNCTION public.insertarccaportessinfacturas(fila aportessinfacturas)
 RETURNS aportessinfacturas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aportessinfacturascc:= current_timestamp;
    UPDATE sincro.aportessinfacturas SET anio= fila.anio, aportessinfacturascc= fila.aportessinfacturascc, centro= fila.centro, idaporte= fila.idaporte, idcentroregionaluso= fila.idcentroregionaluso, mes= fila.mes, nrodoc= fila.nrodoc, tiempopago= fila.tiempopago, tipodoc= fila.tipodoc WHERE anio= fila.anio AND idaporte= fila.idaporte AND idcentroregionaluso= fila.idcentroregionaluso AND mes= fila.mes AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.aportessinfacturas(anio, aportessinfacturascc, centro, idaporte, idcentroregionaluso, mes, nrodoc, tiempopago, tipodoc) VALUES (fila.anio, fila.aportessinfacturascc, fila.centro, fila.idaporte, fila.idcentroregionaluso, fila.mes, fila.nrodoc, fila.tiempopago, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
