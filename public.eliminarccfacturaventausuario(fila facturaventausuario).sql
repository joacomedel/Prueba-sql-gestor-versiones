CREATE OR REPLACE FUNCTION public.eliminarccfacturaventausuario(fila facturaventausuario)
 RETURNS facturaventausuario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturaventausuariocc:= current_timestamp;
    delete from sincro.facturaventausuario WHERE nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
