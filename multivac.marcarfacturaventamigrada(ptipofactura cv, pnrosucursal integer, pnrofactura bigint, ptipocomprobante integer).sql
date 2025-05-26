CREATE OR REPLACE FUNCTION multivac.marcarfacturaventamigrada(ptipofactura character varying, pnrosucursal integer, pnrofactura bigint, ptipocomprobante integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
rta boolean;
tfac alias for $1;
nrosuc alias for $2;
nrofac alias for $3;
tcomp alias for $4;
aux record;
rs CURSOR FOR
   SELECT f.*
   from multivac.facturasventatotal as f
        left join multivac.facturaventa_migrada as m on (f.tipocomprobante=m.tipocomprobante and f.nrosucursal=m.nrosucursal
        and f.nrofactura=m.nrofactura and f.centro=m.centro and f.tipofactura=m.tipofactura and f.iditem=m.iditem)
   WHERE m.fechamigracion is NULL and f.tipofactura=tfac and f.nrosucursal=nrosuc and f.nrofactura=nrofac and f.tipocomprobante=tcomp;

BEGIN
rta = true;

OPEN rs;
FETCH rs into aux;
while found loop
   insert into multivac.facturaventa_migrada(tipocomprobante,nrosucursal,nrofactura,centro,tipofactura,iditem,fechamigracion)
   values (aux.tipocomprobante,aux.nrosucursal,aux.nrofactura,aux.centro, aux.tipofactura,aux.iditem,CURRENT_TIMESTAMP);

   fetch rs into aux;
end loop;
CLOSE rs;
return rta;
END;
$function$
