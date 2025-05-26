CREATE OR REPLACE FUNCTION public.marcarcomomigradafacturaventa(ptipocomprobante integer, pnrosucursal integer, pnrofactura integer, ptipofactura character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
UPDATE public.facturaventa SET migrada=current_timestamp where tipocomprobante=ptipocomprobante and nrosucursal=pnrosucursal and nrofactura=pnrofactura and tipofactura = ptipofactura;
IF FOUND then
return true;
ELSE
return false;
end if;
end;
$function$
