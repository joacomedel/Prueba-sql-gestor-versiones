CREATE OR REPLACE FUNCTION public.libroivadigitalalicuotas_ventas(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_libroivadigitalalicuotas_ventas AS (
 SELECT tccodigo, 
lpad(fv.nrosucursal,5,'0') puntodeventa, 
lpad(fv.nrofactura,20,'0') numerocomprobante,
to_char(SUM( (case when (idconcepto=50840 and porcentaje<>0 and centro = 99 ) then itemfv.importe/(1+porcentaje) --Tener en cuenta que los items de la factura en la farmacia se guardan sin iva, pero el descuento ya tiene incluido el iva
                        else CASE WHEN idconcepto=50840 AND centro <> 99 and porcentaje<>0 THEN 0   
                             ELSE  itemfv.importe END END 
                               
                            )
          ) ,'0000000000000V99') netogravado,
ticodigo,
lpad(0,15,'0') as impuestoliquidado
            
       FROM contabilidad_periodofiscalfacturaventa NATURAL JOIN  facturaventa  as fv 
       JOIN  tipocomprobantecodigo tcc ON (fv.tipocomprobante= tcc.idtipo AND fv.tipofactura = tcc.tipofactura) 
       JOIN itemfacturaventa as itemfv ON (fv.tipofactura= itemfv.tipofactura AND fv.tipocomprobante= itemfv.tipocomprobante AND fv.nrosucursal= itemfv.nrosucursal AND 
fv.nrofactura= itemfv.nrofactura)
       JOIN tipoiva USING (idiva)
       WHERE   
            ( nullvalue(itemfv.nrofactura) or idconcepto <> 20821  ) and 
             idperiodofiscal =  rfiltros.idperiodofiscal  and nullvalue(anulada) and porcentaje= 0
       GROUP BY tccodigo,puntodeventa,ticodigo,numerocomprobante

UNION 


 SELECT tccodigo, 
lpad(fv.nrosucursal,5,'0') puntodeventa, 
lpad(fv.nrofactura,20,'0') numerocomprobante
,to_char(SUM( (case when (idconcepto=50840 and porcentaje<>0 and centro = 99 ) then itemfv.importe/(1+porcentaje) --Tener en cuenta que los items de la factura en la farmacia se guardan sin iva, pero el descuento ya tiene incluido el iva
                        else CASE WHEN idconcepto=50840 AND centro <> 99 and porcentaje<>0 THEN 0   
                             ELSE case when ( porcentaje = 0 ) then 0  ELSE itemfv.importe END END 
                               
                            end )
          ) ,'0000000000000V99') netogravado,
ticodigo,
to_char(SUM((case when porcentaje=.21 then  (itemfv.importe *porcentaje ) else 0 end)
                      * (case when itemfv.importe > 0 then 1 else 0 end)) 
          +
        SUM((case when porcentaje=.21 then (itemfv.importe/(1+porcentaje) * porcentaje ) else 0 end) * (case when itemfv.importe < 0 then 1 else 0 end)) 
 
          ,'0000000000000V99' ) as impuestoliquidado
            
       FROM contabilidad_periodofiscalfacturaventa NATURAL JOIN  facturaventa  as fv 
       JOIN  tipocomprobantecodigo tcc ON (fv.tipocomprobante= tcc.idtipo AND fv.tipofactura = tcc.tipofactura) 
       JOIN itemfacturaventa as itemfv ON (fv.tipofactura= itemfv.tipofactura AND fv.tipocomprobante= itemfv.tipocomprobante AND fv.nrosucursal= itemfv.nrosucursal AND 
fv.nrofactura= itemfv.nrofactura)
       JOIN tipoiva USING (idiva)
       WHERE  
            ( nullvalue(itemfv.nrofactura) or idconcepto <> 20821  ) and 
             idperiodofiscal =  rfiltros.idperiodofiscal  and nullvalue(anulada) and porcentaje= 0.21
       GROUP BY tccodigo,puntodeventa,ticodigo,numerocomprobante

UNION 

SELECT tccodigo, 
lpad(fv.nrosucursal,5,'0') puntodeventa, 
lpad(fv.nrofactura,20,'0') numerocomprobante
,to_char(SUM( (case when (idconcepto=50840 and porcentaje<>0 and centro = 99 ) then itemfv.importe/(1+porcentaje) --Tener en cuenta que los items de la factura en la farmacia se guardan sin iva, pero el descuento ya tiene incluido el iva
                        else CASE WHEN idconcepto=50840 AND centro <> 99 and porcentaje<>0 THEN 0   
                             ELSE case when ( porcentaje = 0 ) then 0  ELSE itemfv.importe END END 
                               
                            end )
          ) ,'0000000000000V99') as netogravado,
ticodigo,
to_char(SUM((case when porcentaje=.105 then (itemfv.importe*porcentaje ) else 0 end)*  (case when itemfv.importe > 0 then 1 else 0 end) ) 
        +
        SUM((case when porcentaje=.105 then (itemfv.importe/(1+porcentaje) * porcentaje ) else 0 end) * (case when itemfv.importe < 0 then 1 else 0 end)) 
       ,'0000000000000V99') as impuestoliquidado
            
       FROM contabilidad_periodofiscalfacturaventa NATURAL JOIN  facturaventa  as fv 
       JOIN  tipocomprobantecodigo tcc ON (fv.tipocomprobante= tcc.idtipo AND fv.tipofactura = tcc.tipofactura) 
       JOIN itemfacturaventa as itemfv ON (fv.tipofactura= itemfv.tipofactura AND fv.tipocomprobante= itemfv.tipocomprobante AND fv.nrosucursal= itemfv.nrosucursal AND 
fv.nrofactura= itemfv.nrofactura)
       JOIN tipoiva USING (idiva)
       WHERE   
            ( nullvalue(itemfv.nrofactura) or idconcepto <> 20821  ) and 
             idperiodofiscal =  rfiltros.idperiodofiscal and nullvalue(anulada) and porcentaje=0.105
       GROUP BY tccodigo,puntodeventa,ticodigo,numerocomprobante

UNION 

SELECT tccodigo, 
lpad(fv.nrosucursal,5,'0') puntodeventa, 
lpad(fv.nrofactura,20,'0') numerocomprobante
,to_char(SUM( (case when (idconcepto=50840 and porcentaje<>0 and centro = 99 ) then itemfv.importe/(1+porcentaje) --Tener en cuenta que los items de la factura en la farmacia se guardan sin iva, pero el descuento ya tiene incluido el iva
                        else CASE WHEN idconcepto=50840 AND centro <> 99 and porcentaje<>0 THEN 0   
                             ELSE case when ( porcentaje = 0 ) then 0  ELSE itemfv.importe END END 
                               
                            end )
          ),'0000000000000V99') as netogravado,
ticodigo,
to_char(SUM((case when porcentaje=.27 then (itemfv.importe *porcentaje ) else 0 end) *  (case when itemfv.importe > 0 then 1 else 0 end) )
         +
        SUM((case when porcentaje=.105 then (itemfv.importe/(1+porcentaje) * porcentaje ) else 0 end) * (case when itemfv.importe < 0 then 1 else 0 end)) 
     
        ,'0000000000000V99') as impuestoliquidado
            
       FROM contabilidad_periodofiscalfacturaventa NATURAL JOIN  facturaventa  as fv 
       JOIN  tipocomprobantecodigo tcc ON (fv.tipocomprobante= tcc.idtipo AND fv.tipofactura = tcc.tipofactura) 
       JOIN itemfacturaventa as itemfv ON (fv.tipofactura= itemfv.tipofactura AND fv.tipocomprobante= itemfv.tipocomprobante AND fv.nrosucursal= itemfv.nrosucursal AND 
fv.nrofactura= itemfv.nrofactura)
       JOIN tipoiva USING (idiva)
       WHERE   
            ( nullvalue(itemfv.nrofactura) or idconcepto <> 20821  ) and 
             idperiodofiscal = rfiltros.idperiodofiscal and nullvalue(anulada) and porcentaje= 0.27
       GROUP BY tccodigo,puntodeventa,ticodigo,numerocomprobante

  ORDER BY puntodeventa,numerocomprobante
 
 ); 

  
  

 
return 'ok';
END;
$function$
