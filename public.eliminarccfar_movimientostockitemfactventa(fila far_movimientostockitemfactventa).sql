CREATE OR REPLACE FUNCTION public.eliminarccfar_movimientostockitemfactventa(fila far_movimientostockitemfactventa)
 RETURNS far_movimientostockitemfactventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemfactventacc:= current_timestamp;
    delete from sincro.far_movimientostockitemfactventa WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND iditem= fila.iditem AND idmovimientostockitem= fila.idmovimientostockitem AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
