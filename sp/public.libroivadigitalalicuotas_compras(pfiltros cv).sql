CREATE OR REPLACE FUNCTION public.libroivadigitalalicuotas_compras(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_libroivadigitalalicuotas_compras AS (
  SELECT tccodigo,  --Según tabla Comprobantes de la afip 
         lpad(rf.puntodeventa,5,'0') puntodeventa,
         lpad(rf.numero,20,'0') numero,
         80 codigovendedor,
         lpad(replace(p.pcuit,'-',''),20,'0') idvendedor,
         to_char(( rf.netoiva21+ rlfrecargo21 -rlfdescuento21) ,'0000000000000V99') AS netogravado, 
         case when rf.iva21<>0 then '0005' end codigoalicuota,
         to_char((rf.iva21+ rlfivarecargo21 - rlfivadescuento21  ) /*- (case when rf.tipofactura='NCR' then rf.iva21 else 0 end)*/ ,'0000000000000V99') impuestoliquidado

FROM  reclibrofact AS rf JOIN prestador p on (rf.idprestador=p.idprestador) JOIN tipocomprobantecodigo tcc ON (rf.idtipocomprobante= tcc.idtipocomprobante AND rf.letra = tcc.tccletra )
JOIN contabilidad_periodofiscalreclibrofact using (idrecepcion,idcentroregional)
WHERE   idperiodofiscal = rfiltros.idperiodofiscal and (rf.iva21<>0)

UNION 

SELECT tccodigo,  --Según tabla Comprobantes de la afip 
lpad(rf.puntodeventa,5,'0') puntodeventa,
lpad(rf.numero,20,'0') numero,
80 codigovendedor,
lpad(replace(p.pcuit,'-',''),20,'0') idvendedor,
to_char( (rf.netoiva105+rlfrecargo105 -rlfdescuento105),'0000000000000V99') AS netogravado, 
case when rf.iva105<>0 then '0004' end codigoalicuota,
to_char( (rf.iva105+ rlfivarecargo105 - rflivadescuento105 ),'0000000000000V99') impuestoliquidado
--,numfactura
FROM  reclibrofact AS rf JOIN prestador p on (rf.idprestador=p.idprestador) JOIN tipocomprobantecodigo tcc ON (rf.idtipocomprobante= tcc.idtipocomprobante AND rf.letra = tcc.tccletra )
JOIN contabilidad_periodofiscalreclibrofact using (idrecepcion,idcentroregional)
WHERE  idperiodofiscal =  rfiltros.idperiodofiscal and (rf.iva105<>0)

UNION 

SELECT tccodigo,  --Según tabla Comprobantes de la afip 
lpad(rf.puntodeventa,5,'0') puntodeventa,
lpad(rf.numero,20,'0') numero,
80 codigovendedor,
lpad(replace(p.pcuit,'-',''),20,'0') idvendedor,
to_char(( rf.netoiva27+rlfrecargo27-rlfdescuento27),'0000000000000V99') AS netogravado, 
case when rf.iva27<>0 then '0006' end codigoalicuota,
to_char( (rf.iva27+ rlfivarecargo27 - rlfivadescuento27),'0000000000000V99') impuestoliquidado
--,numfactura

FROM  reclibrofact AS rf JOIN prestador p on (rf.idprestador=p.idprestador) JOIN tipocomprobantecodigo tcc ON (rf.idtipocomprobante= tcc.idtipocomprobante AND rf.letra = tcc.tccletra )
JOIN contabilidad_periodofiscalreclibrofact using (idrecepcion,idcentroregional)
WHERE  idperiodofiscal = rfiltros.idperiodofiscal and (rf.iva27<>0)



ORDER BY puntodeventa,numero, idvendedor
 
 ); 

  
  

 
return 'ok';
END;
$function$
