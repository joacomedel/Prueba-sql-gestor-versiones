CREATE OR REPLACE FUNCTION public.far_compdesplazamientodecreciente(bigint, integer, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       elnrofactura bigint;
       lasucursal integer;
       eltipofactura varchar;
       eltipocomprobante  integer;
       elmayor bigint;
       cfactura refcursor;
       unfac record;
       prox_fact integer;
BEGIN

      elnrofactura = $1;
      lasucursal =$2;
      eltipofactura = $3;
      eltipocomprobante = $4;
      
      SELECT INTO elmayor max(nrofactura)
      FROM facturaventa
      WHERE nrosucursal=lasucursal
            and tipofactura = eltipofactura
            and tipocomprobante = eltipocomprobante ;

      WHILE (elnrofactura <= elmayor ) LOOP

            UPDATE facturaventa
            SET nrofactura = (elnrofactura -1)
            WHERE nrofactura =elnrofactura and nrosucursal= lasucursal and tipofactura =eltipofactura
                  and tipocomprobante = eltipocomprobante;

            UPDATE far_ordenventaitemitemfacturaventa
            SET nrofactura = (elnrofactura -1)
            WHERE nrofactura =elnrofactura and nrosucursal=lasucursal and tipofactura = eltipofactura
                  and tipocomprobante = eltipocomprobante;
 if  (centro() =1 ) then
            INSERT INTO configuraadminprocesosejecucion(idconfiguraadminprocesos,capedescripcion)
  	    VALUES(99,concat('Voy a cambiar el nro del comprobante desde far_compdesplazamientodecreciente ',eltipofactura,' ',elnrofactura,'-',lasucursal,'/',eltipocomprobante,' por el nro ',(elnrofactura -1) ));

end if;

          elnrofactura = elnrofactura +1;
      END LOOP;

     SELECT INTO prox_fact ( MAX(nrofactura)+1)
     FROM facturaventa
     WHERE nrosucursal=lasucursal and tipofactura = eltipofactura and tipocomprobante = eltipocomprobante ;
     UPDATE talonario SET sgtenumero = prox_fact
     WHERE   nrosucursal=lasucursal and tipofactura = eltipofactura and tipocomprobante = eltipocomprobante ;


return 'true';
END;
$function$
