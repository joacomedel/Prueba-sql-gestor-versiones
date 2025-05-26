CREATE OR REPLACE FUNCTION public.insertarcctalonario(fila talonario)
 RETURNS talonario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.talonariocc:= current_timestamp;
    UPDATE sincro.talonario SET centro= fila.centro, descripcion= fila.descripcion, nrofinal= fila.nrofinal, nroinicial= fila.nroinicial, nrosucursal= fila.nrosucursal, sgtenumero= fila.sgtenumero, talonariocc= fila.talonariocc, timprime= fila.timprime, tipocomprobante= fila.tipocomprobante, tipofactura= fila.tipofactura, vencimiento= fila.vencimiento WHERE centro= fila.centro AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.talonario(centro, descripcion, nrofinal, nroinicial, nrosucursal, sgtenumero, talonariocc, timprime, tipocomprobante, tipofactura, vencimiento) VALUES (fila.centro, fila.descripcion, fila.nrofinal, fila.nroinicial, fila.nrosucursal, fila.sgtenumero, fila.talonariocc, fila.timprime, fila.tipocomprobante, fila.tipofactura, fila.vencimiento);
    END IF;
    RETURN fila;
    END;
    $function$
