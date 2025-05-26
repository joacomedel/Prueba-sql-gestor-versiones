CREATE OR REPLACE FUNCTION public.facturaventa_esposiblemodificarcomprobante_v1(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    rparam RECORD;
    respuesta boolean;
    srespuesta varchar;
    rexiste record;
    rtfvliquidacioniva record;
    rliquidaciontarjeta RECORD;
BEGIN
    respuesta = false;
    EXECUTE sys_dar_filtros($1) INTO rparam;

    -----  BelenA:  me fijo si esta dentro de una liquidacion de tarjeta

    SELECT INTO rliquidaciontarjeta *
                    FROM facturaventacupon    
                    NATURAL JOIN facturaventa   
                    NATURAL JOIN valorescaja    
                    JOIN tipocomprobanteventa on(facturaventa.tipocomprobante=tipocomprobanteventa.idtipo)        
                    LEFT JOIN facturaventacuponlote USING(nrofactura,tipocomprobante,nrosucursal,tipofactura,idfacturacupon,centro)       
                    LEFT JOIN (SELECT idfacturacupon,centro,tipofactura,tipocomprobante,nrofactura,nrosucursal FROM facturaventacuponestado WHERE idordenventaestadotipo=1 AND nullvalue(fvcefechafin)) AS x           
     ON (facturaventacupon.idfacturacupon=x.idfacturacupon AND facturaventacupon.centro=x.centro              AND facturaventacupon.tipofactura=x.tipofactura AND facturaventacupon.tipocomprobante=x.tipocomprobante              
     AND facturaventacupon.nrofactura=x.nrofactura AND facturaventacupon.nrosucursal=x.nrosucursal)     
                    LEFT JOIN liquidaciontarjetaitem AS lti on(facturaventacupon.idfacturacupon=lti.idfacturacupon 
     AND  facturaventacupon.centro=lti.centro AND facturaventacupon.nrosucursal=lti.nrosucursal AND  facturaventacupon.nrofactura=lti.nrofactura 
     AND facturaventacupon.tipocomprobante=lti.tipocomprobante AND  facturaventacupon.tipofactura=lti.tipofactura )  
                    LEFT JOIN liquidaciontarjetaestado as lte USING ( idliquidaciontarjeta, idcentroliquidaciontarjeta) 
                    WHERE 
                        'true'  AND 'true'  AND 'true'  AND 'true'  AND 
                         nullvalue(facturaventa.anulada)  AND not nullvalue(lti.idfacturacupon) AND
                         lti.nrofactura = rparam.nrofactura  AND 
                         lti.nrosucursal=  rparam.nrosucursal AND
                         lti.tipofactura = rparam.tipofactura AND
                         nullvalue(lte.ltefechafin);

    IF FOUND THEN
            
            IF ( (not nullvalue(rliquidaciontarjeta.idtipoestadoliquidaciontarjeta)) AND rliquidaciontarjeta.idtipoestadoliquidaciontarjeta=2) THEN
                -- Esta dentro de una liquidacion de tarjeta y la liquidacion de tarjeta esta cerrada
                srespuesta = concat('La Factura se encuentra dentro de la liquidacion de tarjeta cerrada Nº ', rliquidaciontarjeta.idliquidaciontarjeta ) ;
            ELSE
                -- Esta dentro de una liquidacion de tarjeta y la liquidacion de tarjeta esta abierta, tiene que sacarlo de la liquidacion para poder anularlo
                srespuesta = concat('La Factura se encuentra dentro de la liquidación de tarjeta abierta Nº ', rliquidaciontarjeta.idliquidaciontarjeta , E'\n' ,'Por favor quitar la factura de la liquidación antes de querer eliminarla ');
            END IF;
    
    ELSE

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
                        ELSE
                                srespuesta = concat('El comprobante pertenece a una Liquidacion de IVA que ESTA CERRADA o el Periodo Fiscal ESTA CERRADO !!!  ');
                        END IF;

       ELSE 
             respuesta = true; -- No es un comprobante que liquida iva

       END IF ;

    END IF;



     
RETURN srespuesta;
END;
$function$
