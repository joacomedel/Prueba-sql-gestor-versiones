CREATE OR REPLACE FUNCTION public.fac_ventadiaria(bigint, integer, integer, character varying)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       pnrofactura bigint;
       pnrosucursal integer;
       ptipocomprobante integer;
       ptipofactura varchar;
BEGIN
      pnrofactura  = $1;
      pnrosucursal = $2;
      ptipocomprobante = $3;
      ptipofactura  =$4;

     SELECT INTO elmonto  SUM(importeventa) as ventadiaria
     FROM facturaventa
     NATURAL JOIN (
        SELECT  nrofactura , nrosucursal, tipocomprobante , tipofactura
                ,
                CASE WHEN   idconcepto = 50840 THEN importe
                ELSE (importe + (importe*porcentaje)) END  as importeventa
                FROM itemfacturaventa
                join tipoiva using (idiva)
               --WHERE idiva = 2 --                idconcepto <> 50840
        ) as timporteventa
    WHERE nrofactura = pnrofactura and nrosucursal = pnrosucursal
           and tipocomprobante = ptipocomprobante
           and tipofactura = ptipofactura ;
           
return elmonto;
END;
$function$
