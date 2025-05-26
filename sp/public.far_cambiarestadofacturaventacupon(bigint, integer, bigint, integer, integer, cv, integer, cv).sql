CREATE OR REPLACE FUNCTION public.far_cambiarestadofacturaventacupon(bigint, integer, bigint, integer, integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare

begin
     UPDATE facturaventacuponestado SET fvcefechafin= NOW()
     WHERE idfacturacupon=$1 AND  centro=$2 AND nrofactura=$3 AND tipocomprobante=$4 AND nrosucursal=$5
     AND tipofactura=$6 AND nullvalue(fvcefechafin);
     INSERT INTO facturaventacuponestado (idordenventaestadotipo,idfacturacupon,centro,nrofactura,tipocomprobante
     ,nrosucursal,tipofactura,fvcedescripcion) VALUES($7,$1,$2,$3,$4,$5,$6,$8);
     return true;
end;
$function$
