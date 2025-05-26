CREATE OR REPLACE FUNCTION public.facturaventa_esposiblemodificarcomprobante(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    rparam RECORD;
    respuesta boolean;
    sparam  character varying;
    rexiste record;
    rformapago record; 
    rtfvliquidacioniva record;
BEGIN

     respuesta = false;
     EXECUTE sys_dar_filtros($1) INTO rparam;

     --- 1 Corroboro si el comprobante es un comprobante que liquida iva 
    SELECT INTO rtfvliquidacioniva * 
    FROM tipofacturaventa
    WHERE idtipofactura = rparam.tipofactura AND tfvliquidacioniva;

    IF FOUND THEN 

                    -- 2  Solo es posible modificar un comprobante si el periodo fiscal al que pertenecen NO ESTA CERRADO
                    SELECT INTO rexiste *
                    FROM facturaventa 
                    LEFT JOIN contabilidad_periodofiscalfacturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
                    LEFT JOIN contabilidad_periodofiscal USING(idperiodofiscal)
                    WHERE  nrofactura = rparam.nrofactura and tipocomprobante =  rparam.tipocomprobante
                            and nrosucursal = rparam.nrosucursal and tipofactura = rparam.tipofactura
                            and nullvalue(pfcerrado);
                    IF FOUND THEN --- Si esta en un periodo fiscal y
                            respuesta = true; --- el periodo esta abierto
                    END IF;

   ELSE 
         respuesta = true; -- No es un comprobante que liquida iva
   END IF ;

   /*SELECT INTO rformapago *
                    FROM facturaventacupon natural join valorescaja
                    WHERE  nrofactura = rparam.nrofactura and tipocomprobante =  rparam.tipocomprobante
                            and nrosucursal = rparam.nrosucursal and tipofactura = rparam.tipofactura
                            and idformapagotipos<>3;
   IF FOUND THEN 
               respuesta = true; -- Es un comprobante que se puede modificar pq su formapagostipos es distinto de ctacte
   else
               respuesta = false;
    END IF ;
*/
               
     
return respuesta;
END;
$function$
