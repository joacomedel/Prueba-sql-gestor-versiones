CREATE OR REPLACE FUNCTION public.eliminarccfar_liquidacionitemfvc(fila far_liquidacionitemfvc)
 RETURNS far_liquidacionitemfvc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionitemfvccc:= current_timestamp;
    delete from sincro.far_liquidacionitemfvc WHERE centro= fila.centro AND idfacturacupon= fila.idfacturacupon AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
