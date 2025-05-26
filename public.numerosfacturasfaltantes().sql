CREATE OR REPLACE FUNCTION public.numerosfacturasfaltantes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
--facturas cursor for select * from controlfacturas order by nrofactura;
fac record;
anterior bigint;
ultimo bigint;
begin
anterior = 1;
select into ultimo max(nrofactura) from facturaventa where fechaemision = '2008-06-30' and tipofactura='FA';
--open facturas;
--fetch facturas into fac;
while (anterior <= ultimo) loop
      if not exists(select * from controlfacturas where nrofactura=anterior) then
         insert into facturaserror(nrofactura, motivo) values(anterior,'FALTANTE');
         end if;
      anterior = anterior + 1;
end loop;
return true;
end;
$function$
