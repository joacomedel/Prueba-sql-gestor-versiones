CREATE OR REPLACE FUNCTION public.eliminarcctalonario(fila talonario)
 RETURNS talonario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.talonariocc:= current_timestamp;
    delete from sincro.talonario WHERE centro= fila.centro AND nrosucursal= fila.nrosucursal AND tipocomprobante= fila.tipocomprobante AND tipofactura= fila.tipofactura AND TRUE;
    RETURN fila;
    END;
    $function$
