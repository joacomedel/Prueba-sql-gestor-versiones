CREATE OR REPLACE FUNCTION public.insertarccfar_movimientostockitemfactventa(fila far_movimientostockitemfactventa)
 RETURNS far_movimientostockitemfactventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_movimientostockitemfactventacc:= current_timestamp;
    UPDATE sincro.far_movimientostockitemfactventa SET far_movimientostockitemfactventacc= fila.far_movimientostockitemfactventacc, idcentromovimientostockitem= fila.idcentromovimientostockitem, iditem= fila.iditem, idmovimientostockitem= fila.idmovimientostockitem, nrofactura= fila.nrofactura, nrosucursal= fila.nrosucursal, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura WHERE idcentromovimientostockitem= fila.idcentromovimientostockitem AND iditem= fila.iditem AND idmovimientostockitem= fila.idmovimientostockitem AND nrofactura= fila.nrofactura AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_movimientostockitemfactventa(far_movimientostockitemfactventacc, idcentromovimientostockitem, iditem, idmovimientostockitem, nrofactura, nrosucursal, tipocomprobante, tipofactura) VALUES (fila.far_movimientostockitemfactventacc, fila.idcentromovimientostockitem, fila.iditem, fila.idmovimientostockitem, fila.nrofactura, fila.nrosucursal, fila.tipocomprobante, fila.tipofactura);
    END IF;
    RETURN fila;
    END;
    $function$
