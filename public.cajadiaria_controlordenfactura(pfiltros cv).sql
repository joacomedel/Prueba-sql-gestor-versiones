CREATE OR REPLACE FUNCTION public.cajadiaria_controlordenfactura(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
 

--RECORD    
rfiltros RECORD; 
rcompfacturas RECORD;  
rcompncs RECORD; 
--VARIABLES
respuesta VARCHAR DEFAULT 'Todook';
 
BEGIN

  EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
  SELECT INTO rcompfacturas COUNT(nrofactura) cantidad, text_concatenar(concat(nrofactura,'-', tipocomprobante,'-', nrosucursal,'-', tipofactura) ) as comprobantes 
   FROM facturaorden NATURAL JOIN facturaventa
   WHERE nroorden =rfiltros.nroorden AND centro= rfiltros.centro  AND idcomprobantetipos=rfiltros.idcomprobantetipos AND tipofactura='FA' AND nullvalue(anulada);
   
  SELECT INTO rcompncs  COUNT(nrofactura) cantidad, text_concatenar(concat(nrofactura,'-', tipocomprobante,'-', nrosucursal,'-', tipofactura) ) as comprobantes 
   FROM facturaorden NATURAL JOIN facturaventa
   WHERE nroorden = rfiltros.nroorden AND centro= rfiltros.centro AND idcomprobantetipos=rfiltros.idcomprobantetipos AND tipofactura='NC' AND nullvalue(anulada); 
  
  IF rcompfacturas.cantidad<>rcompncs.cantidad and rfiltros.tipofactura ='FA'  THEN 
        RAISE EXCEPTION ' La orden ya se encuentra facturada !! %', rcompfacturas USING HINT = 'Verificar el comprobante de facturacion .';       
  END IF;
 

  
return respuesta;

END;
$function$
