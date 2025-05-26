CREATE OR REPLACE FUNCTION public.calcularmonto(integer)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
declare
        resultado record;
begin
 SELECT into resultado nrofactura,facturaventacupon.tipofactura,facturaventacupon.nrosucursal,
 facturaventacupon.tipocomprobante,
  sum(monto)  as sumacartaautomatica
from facturaventacupon

 where  idvalorescaja=$1;
  
return resultado;
end;
$function$
