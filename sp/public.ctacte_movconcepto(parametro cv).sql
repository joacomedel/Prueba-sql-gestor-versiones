CREATE OR REPLACE FUNCTION public.ctacte_movconcepto(parametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$ 
DECLARE
       
--RECORD
       rfiltros RECORD;
     
--VARIABLES
       vdatosconcepto VARCHAR;
       vnrooden VARCHAR;
       
       
BEGIN
   EXECUTE sys_dar_filtros(parametro) INTO rfiltros;

   SELECT INTO vdatosconcepto concat ( denominacion,' Nro.Cliente: ', nrocliente,'-', cliente.barra,    text_concatenar(case when not nullvalue(fo.nroorden) then  concat('Nro. Orden: ',fo.nroorden,'-',fo.centro  ) end ))  
   FROM facturaventa fv JOIN cliente ON (nrodoc= nrocliente  and fv.barra=cliente.barra) LEFT JOIN facturaorden 	fo USING(nrofactura,tipofactura,tipocomprobante ,nrosucursal) 
--   WHERE fv.nrofactura = 243673 AND fv.tipofactura ='FA' AND fv.tipocomprobante = 1 AND fv.nrosucursal = 1

   WHERE fv.nrofactura = rfiltros.nrofactura AND fv.tipofactura = rfiltros.tipofactura AND fv.tipocomprobante = rfiltros.tipocomprobante AND fv.nrosucursal = rfiltros.nrosucursal
   GROUP BY denominacion,nrocliente, cliente.barra;
 
--KR 07-10-21 para los casos en que la orden no se encontro pero esta en la temporal lo chequeo
  IF vdatosconcepto not ilike '%Nro. Orden%' THEN 
     IF iftableexists('temporden') THEN
        SELECT INTO vnrooden concat('Orden/es: ', text_concatenar(concat(nroorden,'-',centro )))
          FROM temporden;
        vdatosconcepto = concat (vdatosconcepto , ' ', vnrooden ) ;
     END IF;
  END IF;  
   return vdatosconcepto;

END;$function$
