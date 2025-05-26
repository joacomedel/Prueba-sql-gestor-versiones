CREATE OR REPLACE FUNCTION public.insertarccfacturaaporte(fila facturaaporte)
 RETURNS facturaaporte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaaportecc:= current_timestamp;
    UPDATE sincro.facturaaporte SET anio= fila.anio, facturaaportecc= fila.facturaaportecc, idaporte= fila.idaporte, idcentroregionaluso= fila.idcentroregionaluso, mes= fila.mes, nrodoc= fila.nrodoc, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipodoc= fila.tipodoc, tipofactura= fila.tipofactura WHERE anio= fila.anio AND mes= fila.mes AND nrodoc= fila.nrodoc AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipodoc= fila.tipodoc AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturaaporte(anio, facturaaportecc, idaporte, idcentroregionaluso, mes, nrodoc, nrofactura, nrosucursal, tipocomprobante, tipodoc, tipofactura) VALUES (fila.anio, fila.facturaaportecc, fila.idaporte, fila.idcentroregionaluso, fila.mes, fila.nrodoc, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipodoc, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
