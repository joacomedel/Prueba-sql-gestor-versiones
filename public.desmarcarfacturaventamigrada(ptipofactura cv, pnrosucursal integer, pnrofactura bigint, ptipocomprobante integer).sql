CREATE OR REPLACE FUNCTION public.desmarcarfacturaventamigrada(ptipofactura character varying, pnrosucursal integer, pnrofactura bigint, ptipocomprobante integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
rta boolean;
tfac alias for $1;
nrosuc alias for $2;
nrofac alias for $3;
tcomp alias for $4;

BEGIN
rta = true;

delete from facturaventa_migrada
where tipocomprobante=tcomp and nrosucursal=nrosuc and nrofactura=nrofac and tipofactura=tfac;
if not found then
   rta=false;
end if;

return rta;
END
$function$
