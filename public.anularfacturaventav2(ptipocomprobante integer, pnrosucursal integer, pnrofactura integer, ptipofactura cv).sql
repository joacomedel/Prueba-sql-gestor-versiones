CREATE OR REPLACE FUNCTION public.anularfacturaventav2(ptipocomprobante integer, pnrosucursal integer, pnrofactura integer, ptipofactura character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
auxordenes CURSOR FOR SELECT * FROM facturaorden where (nrosucursal=pnrosucursal and nrofactura=pnrofactura and tipofactura=ptipofactura and tipocomprobante=ptipocomprobante);
elemorden record;
auxaportes CURSOR FOR SELECT * FROM facturaaporte where (nrosucursal=pnrosucursal and nrofactura=pnrofactura and tipofactura=ptipofactura and tipocomprobante=ptipocomprobante);
elemaporte record;
begin

open auxordenes;
fetch auxordenes into elemorden;
while found loop
      insert into ordenessinfacturas (nroorden,centro) values(elemorden.nroorden,elemorden.centro);
      fetch auxordenes into elemorden;
end loop;
close auxordenes;


open auxaportes;
fetch  auxaportes into elemaporte;
while found loop
      insert into aportessinfacturas (nrodoc,tipodoc,mes,anio)
         values(elemaporte.nrodoc,elemaporte.tipodoc,elemaporte.mes,elemaporte.anio);
      fetch  auxaportes into elemaporte;
end loop;
close auxaportes;


UPDATE public.facturaventa
SET anulada=current_timestamp
where tipocomprobante=ptipocomprobante and nrosucursal=pnrosucursal and nrofactura=pnrofactura and tipofactura=ptipofactura;

IF FOUND then
return true;
ELSE
return false;
end if;
end;
$function$
