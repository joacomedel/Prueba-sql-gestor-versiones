CREATE OR REPLACE FUNCTION public.libroivadigital_ventas(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;  

CREATE TEMP  TABLE temp_libroivadigital_ventas
AS (

SELECT TO_CHAR( fv.fechaemision :: DATE, 'yyyymmdd')::numeric fechacomprobante,tccodigo, lpad(fv.nrosucursal,5,'0') puntodeventa, lpad(fv.nrofactura,20,'0') numerocomprobante, lpad(fv.nrofactura,20,'0') numerocomprobantehasta,
case when fv.tipocomprobante=2 then 80 else 96 end codigocomprador, -- tabla de Tipo de Documento de la afip
--si la longitud es correcta va el cuit, sino y el tipo de comprobante no es A va el cuit de 000000000 sino tiene que dar error y hay que poner el cuit correcto en cliente
case when fv.tipocomprobante=2 and length(concat(cuitini, cuitmedio, cuitfin))=11 then lpad(concat(cuitini, cuitmedio, cuitfin),20,'0') 
    else case when fv.tipocomprobante<>2 then lpad(fv.nrodoc,20,'0') end end as idcomprador, 

rpad(c.denominacion,30,' ') denominacion,
to_char((CASE WHEN (nullvalue(importeamuc)) THEN 0 ELSE importeamuc END     
                            +CASE WHEN (nullvalue(importeefectivo)) THEN 0 ELSE importeefectivo END  
                            +CASE WHEN (nullvalue(importesosunc)) THEN 0 ELSE importesosunc END  
                            +CASE WHEN (nullvalue(importedebito)) THEN 0 ELSE importedebito END 
                            +CASE WHEN (nullvalue(importectacte)) THEN 0 ELSE importectacte END 
                            +CASE WHEN (nullvalue(importecredito)) THEN 0 ELSE importecredito END  
                         ) ,'0000000000000V99')    as importetotal,
lpad(0,15,'0') nogravado,
lpad(0,15,'0') percnocategorizados, 
lpad(0,15,'0') exento,
lpad(0,15,'0') impnacionales,
lpad(0,15,'0') perciibb, 
lpad(0,15,'0') percimpmuni, 
lpad(0,15,'0') impinternos, 
'PES' as codigomoneda,
'0001000000' tipocambio,
cantalicuotas ,
rpad(case when nullvalue(itemfv.codoperacion) then ' ' else itemfv.codoperacion end,1,' ') codoperacion, --NO CORRESPONDE Segun tabla . Código de Operación del afip
lpad(0,15,'0') otrostributos,
lpad(0,8,'0') vencimientopago

FROM contabilidad_periodofiscalfacturaventa NATURAL JOIN facturaventa fv JOIN  tipocomprobantecodigo tcc ON (fv.tipocomprobante= tcc.idtipo AND fv.tipofactura = tcc.tipofactura) 
JOIN (
SELECT T.tipofactura,T.tipocomprobante,T.nrosucursal,T.nrofactura, sum(importe) importe, sum(cantalicuotas) cantalicuotas,text_concatenar(codoperacion ) codoperacion 
FROM (
SELECT  tipofactura,tipocomprobante,nrosucursal,nrofactura, sum(importe) importe,  
 case when  idiva=1  then 1 else 0 end + case when  idiva=2  then 1 else 0 end + case when  idiva=3 then 1 else 0 end + case when  idiva=4 then 1 else 0 end  cantalicuotas, case when tipocomprobante = 2  AND idiva<>1 then null else  'N' end as codoperacion
FROM itemfacturaventa 
 --where nrofactura =659 and nrosucursal=1 and tipofactura='NC' and tipocomprobante = 1
 GROUP BY tipofactura,tipocomprobante,nrosucursal, nrofactura,idiva) AS T
GROUP BY tipofactura,tipocomprobante,nrosucursal, nrofactura) AS itemfv ON (fv.tipofactura= itemfv.tipofactura AND fv.tipocomprobante= itemfv.tipocomprobante AND fv.nrosucursal= itemfv.nrosucursal AND 
fv.nrofactura= itemfv.nrofactura)
LEFT JOIN cliente c ON (fv.nrodoc=c.nrocliente and fv.tipodoc=c.barra)
 

--WHERE nullvalue(anulada) and idperiodofiscal = 925
WHERE   nullvalue(anulada) and idperiodofiscal = rfiltros.idperiodofiscal
 
ORDER BY puntodeventa,numerocomprobante
);

return 'Ok';
END;
$function$
