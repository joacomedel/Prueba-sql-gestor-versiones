CREATE OR REPLACE FUNCTION multivac.desmarcarfacturaventatmp(ptipofactura character varying, pnrosucursal integer, pnrofactura bigint, ptipocomprobante integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
rta boolean;
tfac alias for $1;
nrosuc alias for $2;
nrofac alias for $3;
tcomp alias for $4;
aux RECORD;

BEGIN
rta = true;

SELECT INTO aux * FROM multivac.facturaventatmp
where tipocomprobante=tcomp and nrosucursal=nrosuc and nrofactura=nrofac and tipofactura=tfac;
if not found then
   rta=false;
else
insert into multivac.facturaventa_migrada
(tipocomprobante,nrosucursal,nrofactura,centro,tipofactura,iditem,fechamigracion,estaanulada)
values (aux.tipocomprobante,aux.nrosucursal,aux.nrofactura,aux.centro,aux.tipofactura,aux.iditem,current_date,aux.estaanulada);

delete from multivac.facturaventatmp
where tipocomprobante=tcomp and nrosucursal=nrosuc and nrofactura=nrofac and tipofactura=tfac;

end if;



return rta;
END
$function$
