CREATE OR REPLACE FUNCTION public.facturaventa_cliente_correcto(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD
    rfiltros RECORD;
    rmismocliente RECORD;
--VARIABLES
    respuesta BOOLEAN;
    
BEGIN

     respuesta = true;
     EXECUTE sys_dar_filtros($1) INTO rfiltros;

     SELECT INTO rmismocliente * FROM informefacturacion as if NATURAL JOIN facturaventa as fv 
		WHERE trim(if.nrocliente) <>trim(fv.nrodoc) AND fv.tipocomprobante = rfiltros.tipocomprobante AND fv.nrosucursal = rfiltros.nrosucursal  AND fv.nrofactura = rfiltros.nrofactura AND fv.tipofactura = rfiltros.tipofactura;
	 
     IF FOUND THEN
            RAISE NOTICE 'La factura y su cliente (%)',concat(rmismocliente.nrosucursal,'-',rmismocliente.nrofactura,'-',rmismocliente.nrodoc,'-',rmismocliente.tipocomprobante,'-',rmismocliente.tipofactura);
            RAISE NOTICE 'El Informe y su cliente (%)',concat(rmismocliente.nrocliente,'-',rmismocliente.nroinforme ,'-',rmismocliente.idcentroinformefacturacion,'-',rmismocliente.idinformefacturaciontipo,'-',rmismocliente.barra,'-',rmismocliente.nrofactura,'#',rmismocliente.fechainforme,'#',rmismocliente.informefacturacioncc);

            respuesta = false;
            RAISE EXCEPTION ' El cliente del comprobante de facturación NO ES EL MISMO que estaba pendiente de facturar (en el informe)!! %', rmismocliente USING HINT = 'Verificar el comprobante de facturacion impreso.';
       
     
     END IF;
     
return respuesta;
END;
$function$
