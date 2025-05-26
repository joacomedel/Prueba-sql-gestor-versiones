CREATE OR REPLACE FUNCTION public.fac_ivadiario(bigint, integer, integer, character varying)
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


  	 SELECT  INTO elmonto SUM(importeivadiario) as ivadiario
     FROM facturaventa
     NATURAL JOIN (
                SELECT  nrofactura , nrosucursal, tipocomprobante , tipofactura ,
                CASE WHEN  ( idconcepto = 50840 and porcentaje<> 0 )
                          THEN -1 *(abs(importe) -  (abs(importe) / (1+ porcentaje ) ))
                     WHEN  ( idconcepto = 50840 and porcentaje = 0 )
                           THEN 0
                ELSE (importe*porcentaje)  END  as importeivadiario

                FROM itemfacturaventa
                JOIN tipoiva USING (idiva)
      ) as tivadiario
     WHERE nrofactura = pnrofactura and nrosucursal = pnrosucursal
           and tipocomprobante = ptipocomprobante
           and tipofactura = ptipofactura ;
		
		
		

return elmonto;
END;
$function$
