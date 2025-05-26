CREATE OR REPLACE FUNCTION public.contarfacturasfaltantes(c integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$declare
facturas cursor for select * from facturaventa where centro=c and tipofactura='FA' order by nrofactura;
factura record;
contador integer := 0;
actual integer;
begin
open facturas;
fetch facturas into factura;
if FOUND then
  actual := factura.nrofactura;
  fetch facturas into factura;
  while FOUND loop
     if actual + 1 < factura.nrofactura then
        contador:= contador + (factura.nrofactura - actual - 1);
     end if;
     actual := factura.nrofactura;
     fetch facturas into factura;
  end loop;
end if;
close facturas;
return contador;
end;$function$
