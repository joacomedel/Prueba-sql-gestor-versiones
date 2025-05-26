CREATE OR REPLACE FUNCTION public.far_arreglarcomprobantes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
elnrofactura bigint;
elmayor bigint;
lasucursal integer;
eltipocomprobante  integer;
eltipofactura varchar;
cfactura refcursor;
unfac record;
BEGIN
      lasucursal = 4;
      eltipofactura ='FA';
      eltipocomprobante = 1;

      SELECT INTO elmayor max(nrofactura)
      FROM facturaventa
      WHERE nrosucursal=lasucursal
            and tipofactura = eltipofactura
            and tipocomprobante = eltipocomprobante
            and tipocomprobante = 1 ;

      elnrofactura =  elmayor ;

     -- elnrofactura = 138781 ;
      WHILE (elnrofactura >= 139140 ) LOOP
      
            UPDATE facturaventa
            SET nrofactura = (elnrofactura +1)
            WHERE nrofactura =elnrofactura and nrosucursal= lasucursal and tipofactura =eltipofactura
                  and tipocomprobante = eltipocomprobante;

            UPDATE far_ordenventaitemitemfacturaventa
            SET nrofactura = (elnrofactura +1)
            WHERE nrofactura =elnrofactura and nrosucursal=lasucursal and tipofactura = eltipofactura
                  and tipocomprobante = eltipocomprobante;

          elnrofactura = elnrofactura - 1 ;
      END LOOP;

     UPDATE talonario SET sgtenumero = elmayor +2
     WHERE   nrosucursal=lasucursal and tipofactura = eltipofactura and tipocomprobante = 1 ;


return 'true';
END;
$function$
