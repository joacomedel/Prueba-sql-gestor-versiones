CREATE OR REPLACE FUNCTION public.eliminarccfacturaaporte(fila facturaaporte)
 RETURNS facturaaporte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaaportecc:= current_timestamp;
    delete from sincro.facturaaporte WHERE anio= fila.anio AND mes= fila.mes AND nrodoc= fila.nrodoc AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipodoc= fila.tipodoc AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
