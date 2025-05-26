CREATE OR REPLACE FUNCTION public.itemfacturaventaimportetotal(integer, bigint, integer, character varying)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE

       
       montof double precision;


BEGIN

SELECT INTO montof  sum(importe) as sumatotal,nrosucursal, nrofactura, tipocomprobante, tipofactura 
FROM itemfacturaventa WHERE importe > 0 and nrosucursal=$1 and  nrofactura=$2 and tipocomprobante=$3
and  tipofactura =$4 
GROUP BY nrosucursal, nrofactura, tipocomprobante, tipofactura;

RETURN montof;
END;

$function$
