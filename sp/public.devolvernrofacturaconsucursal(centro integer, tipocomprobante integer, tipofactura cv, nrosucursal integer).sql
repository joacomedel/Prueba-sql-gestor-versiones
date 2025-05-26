CREATE OR REPLACE FUNCTION public.devolvernrofacturaconsucursal(centro integer, tipocomprobante integer, tipofactura character varying, nrosucursal integer)
 RETURNS talonario
 LANGUAGE plpgsql
AS $function$
declare
      resultado talonario%ROWTYPE;
begin
      select into resultado * 
      FROM talonario 
      WHERE talonario.centro=centro 
      AND talonario.tipocomprobante=tipocomprobante 
      AND talonario.tipofactura = tipofactura 
      AND vencimiento >= CURRENT_DATE 
      AND sgtenumero <= nrofinal
      AND talonario.nrosucursal = nrosucursal ;
if NOT FOUND then
        RAISE EXCEPTION 'No se puede asentar la factura de venta. El motivo puede ser, o que el talonario este vencido, o que se haya llegado a la última factura del talonario';
else
 update talonario set sgtenumero=sgtenumero+1 
 WHERE talonario.centro=centro 
       AND talonario.tipocomprobante = tipocomprobante 
       AND talonario.tipofactura = tipofactura
       AND talonario.nrosucursal = nrosucursal;
 return resultado;
end if;
end;
$function$
