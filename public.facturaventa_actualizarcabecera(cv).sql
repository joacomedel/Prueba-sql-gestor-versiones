CREATE OR REPLACE FUNCTION public.facturaventa_actualizarcabecera(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/* Funcion que realiza la imputación  entre deudas y pagos
*/
DECLARE
       rdata record;
BEGIN
         EXECUTE sys_dar_filtros($1) INTO rdata;

         UPDATE facturaventa SET importeefectivo = T.impefect
         FROM(
              SELECT tipofactura, tipocomprobante, nrosucursal, nrofactura, SUM(monto) as impefect
              FROM facturaventacupon
              NATURAL JOIN facturaventa
              NATURAL JOIN valorescaja
              WHERE  nrosucursal =rdata.nrosucursal and idformapagotipos <> 3
              and nrofactura=rdata.nrofactura and tipocomprobante =rdata.tipocomprobante and tipofactura =rdata.tipofactura
              group by tipofactura, tipocomprobante, nrosucursal, nrofactura
         )as T
         WHERE   T.impefect <>facturaventa.importeefectivo
                 and T.tipofactura = facturaventa.tipofactura
                 and T.tipocomprobante  = facturaventa.tipocomprobante
                 and T.nrosucursal  = facturaventa.nrosucursal
                 and T.nrofactura  = facturaventa.nrofactura;

         ------ Actualizar el importe ctacte de facturaventa
         UPDATE facturaventa
         SET importectacte = T.impctacte
         FROM
             (SELECT tipofactura, tipocomprobante, nrosucursal, nrofactura, SUM(monto) as impctacte
              FROM facturaventacupon
              NATURAL JOIN facturaventa
              NATURAL JOIN valorescaja
              WHERE  idformapagotipos =3
                     and nrofactura=rdata.nrofactura and tipocomprobante =rdata.tipocomprobante and tipofactura =rdata.tipofactura
              group by tipofactura, tipocomprobante, nrosucursal, nrofactura
         )as T
         WHERE   T.impctacte <>facturaventa.importectacte
                and T.tipofactura = facturaventa.tipofactura
                and T.tipocomprobante  = facturaventa.tipocomprobante
                and T.nrosucursal  = facturaventa.nrosucursal
                and T.nrofactura  = facturaventa.nrofactura;

RETURN 1;
END;
$function$
