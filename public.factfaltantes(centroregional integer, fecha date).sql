CREATE OR REPLACE FUNCTION public.factfaltantes(centroregional integer, fecha date)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$declare
--facturas cursor for select * from controlfacturas order by nrofactura;
fac record;
cont bigint := 0;
anterior bigint;
ultimo bigint;
begin
anterior = 1;
select into ultimo max(nrofactura) from facturaventa where fechaemision <= fecha and centro=centroregional and tipofactura='FA' and tipocomprobante=1;
--open facturas;
--fetch facturas into fac;
while (anterior <= ultimo) loop
      if not exists(select * from facturaventa where centro=centroregional and tipofactura='FA' and  nrofactura=anterior and tipocomprobante=1) then
         RAISE NOTICE '%',anterior;
         cont=cont+1;
         end if;
      anterior = anterior + 1;
end loop;
return cont;
end;
$function$
