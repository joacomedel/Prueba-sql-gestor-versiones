CREATE OR REPLACE FUNCTION public.facturaventacuponlote_agreganrocomercio_fc(fila facturaventacuponlote)
 RETURNS facturaventacuponlote
 LANGUAGE plpgsql
AS $function$
DECLARE
    rcupon RECORD;
BEGIN

    select into rcupon nrocomercio from valorescajacomercio natural join valorescaja natural join facturaventacupon f
    where idposnet=fila.idposnet and f.idfacturacupon = fila.idfacturacupon AND f.centro=fila.centro and f.nrosucursal=fila.nrosucursal and f.nrofactura=fila.nrofactura and f.tipofactura=fila.tipofactura and f.tipocomprobante=fila.tipocomprobante;

    fila.nrocomercio:= rcupon.nrocomercio;	

    return fila;
END;
$function$
