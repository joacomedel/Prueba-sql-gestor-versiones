CREATE OR REPLACE FUNCTION public.far_eliminarcomprobantenoemitido_arregla_talonario(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
       ptipocomprobante integer;
       pnrosucursal integer;
       pnrofactura bigint;
       ptipofactura varchar ;
       resp boolean;
       respuestaeliminar boolean;
       elmayor bigint;

BEGIN
    
    -- Antes que nada verifico que existan todas las FK que deben existir para garantizar la robustez y buen funcionamiento del SP
     SELECT INTO respuestaeliminar * FROM existefkey();
     IF (not respuestaeliminar) THEN return false; END IF ;

     pnrofactura  =$1;
     pnrosucursal =$2;
     ptipocomprobante =$3;
     ptipofactura  =$4;
     SELECT INTO resp far_eliminarcomprobantenoemitido(pnrofactura,pnrosucursal,ptipocomprobante,ptipofactura);

    
      SELECT INTO elmayor  CASE WHEN max(nrofactura) is null THEN 0 ELSE  max(nrofactura) END
      FROM facturaventa
      WHERE nrosucursal=pnrosucursal
            and tipofactura = ptipofactura
            and tipocomprobante = ptipocomprobante ;

      UPDATE talonario SET sgtenumero = elmayor+1
	WHERE nrosucursal=pnrosucursal and tipofactura = ptipofactura and tipocomprobante = ptipocomprobante ;

return resp;
END;
$function$
