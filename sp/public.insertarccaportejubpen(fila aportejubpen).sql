CREATE OR REPLACE FUNCTION public.insertarccaportejubpen(fila aportejubpen)
 RETURNS aportejubpen
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aportejubpencc:= current_timestamp;
    UPDATE sincro.aportejubpen SET ajpfechaingreso= fila.ajpfechaingreso, anio= fila.anio, aportejubpencc= fila.aportejubpencc, barra= fila.barra, cancelado= fila.cancelado, fechafinaport= fila.fechafinaport, fechainiaport= fila.fechainiaport, idaporte= fila.idaporte, idcentroregionaluso= fila.idcentroregionaluso, importe= fila.importe, mes= fila.mes, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE anio= fila.anio AND idaporte= fila.idaporte AND idcentroregionaluso= fila.idcentroregionaluso AND mes= fila.mes AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.aportejubpen(ajpfechaingreso, anio, aportejubpencc, barra, cancelado, fechafinaport, fechainiaport, idaporte, idcentroregionaluso, importe, mes, nrodoc, tipodoc) VALUES (fila.ajpfechaingreso, fila.anio, fila.aportejubpencc, fila.barra, fila.cancelado, fila.fechafinaport, fila.fechainiaport, fila.idaporte, fila.idcentroregionaluso, fila.importe, fila.mes, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
