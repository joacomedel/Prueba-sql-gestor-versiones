CREATE OR REPLACE FUNCTION multivac.marcarfacturaventamigrada_v2(ptipofactura character varying, pnrosucursal integer, pnrofactura bigint, ptipocomprobante integer, pidcomprobantemultivac bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
rta boolean;
tfac alias for $1;
nrosuc alias for $2;
nrofac alias for $3;
tcomp alias for $4;
idmultivac alias for $5;

BEGIN
rta = true;

insert into multivac.facturaventa_migrada(tipocomprobante,nrosucursal,nrofactura,centro,tipofactura,iditem,fechamigracion,idcomprobantemultivac)
values (tcomp,nrosuc,nrofac,centro(), tfac,0,CURRENT_TIMESTAMP,idmultivac);

/* Tanto el valor de Centro como el de idItem los seteo porque en este nueva version del proceso no me interesan. Cristian marzo/2011 */

return rta;
END;
$function$
