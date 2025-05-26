CREATE OR REPLACE FUNCTION public.facturasfaltantes(idcentro integer, fechadesde date, fechahasta date, tipofac text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
hayfaltantes boolean := false;
facturas cursor for select * from facturaventa natural join talonario where fechaemision <= fechahasta and fechaemision >= fechadesde and tipofactura=tipofac and centro=idcentro order by nrofactura;
fac record;
anterior bigint;
--ultimo bigint;
begin
select into anterior  min(nrofactura) from facturaventa natural join talonario where fechaemision <= fechahasta and fechaemision >= fechadesde and tipofactura=tipofac and centro=idcentro;
open facturas;
fetch facturas into fac;
while FOUND loop
   if fac.nrofactura>anterior then
            hayfaltantes = true;
            while(anterior < fac.nrofactura) loop
                      insert into facturaserror(nrofactura, tipofactura, centro) values(anterior,                    tipofac,idcentro);
                      anterior := anterior + 1;
           end loop;
   end if;
   fetch facturas into fac;
   anterior := anterior + 1;
end loop;
return hayfaltantes;
end;
$function$
