CREATE OR REPLACE FUNCTION public.ctacte_montos(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD
  rfiltros RECORD;
  rorigenctacte   RECORD;
--VARIABLES 
  vimporte DOUBLE PRECISION;
BEGIN
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_tesoreria_reporteordenesfacturadas AS (
     
SELECT concat(p2.apellido,', ', p2.nombres) elafiliado,   concat(p2.nrodoc, '-', p2.barra) nroafiliado,concat(fv.tipofactura,' ',desccomprobanteventa,' ',lpad(fv.nrosucursal,4,'0'),'-',lpad(fv.nrofactura,8,'0')) as comprobante, fv.fechaemision as emisionfactura,text_concatenar(concat('F. Emision:', orden.fechaemision, ' Orden: ',orden.nroorden,'-',orden.centro, '  Afiliado: ',p.nrodoc, '-', p.barra )) lasordenes,ccd.importe, ccd.saldo, ccd.movconcepto , case when nullvalue(T.pendiente) then 'no' else T.pendiente end ,text_concatenar( concat(ccdp.idpago,'-', ccdp.idcentropago)) elpago 
 

FROM persona p NATURAL JOIN consumo NATURAL JOIN orden NATURAL JOIN facturaorden fo JOIN facturaventa fv USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
JOIN tipocomprobanteventa tcv on (fv.tipocomprobante=tcv.idtipo) JOIN informefacturacion if USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
JOIN cuentacorrientedeuda ccd on (ccd.idcomprobante= (if.nroinforme*100)+if.idcentroinformefacturacion AND ccd.idcomprobantetipos=21 )
JOIN persona p2 on (ccd.nrodoc=p2.nrodoc AND ccd.tipodoc=p2.tipodoc)



LEFT JOIN cuentacorrientedeudapago ccdp USING(iddeuda, idcentrodeuda)
LEFT JOIN (SELECT consumo.*,case when not nullvalue(orden.nroorden) THEN 'si' else 'no' END AS pendiente
FROM orden NATURAL JOIN consumo NATURAL JOIN cambioestadosorden
LEFT JOIN facturaorden fo USING(nroorden, centro)
WHERE idordenventaestadotipo= 1 AND nullvalue(fo.nrofactura) AND not (anulado) AND nullvalue(ceofechafin) AND tipo=56 and idasocconv=127 ) as T on(p2.nrodoc=T.nrodoc AND p2.tipodoc=T.tipodoc) 
WHERE fv.fechaemision >='2022-03-20' and orden.tipo=56 and nullvalue(fv.anulada) /* AND (fv.nrodoc='25725142'  or fv.nrodoc='13047676')*/
GROUP BY p2.apellido,p2.nombres,p2.nrodoc,p2.barra, fv.fechaemision,ccd.importe, ccd.saldo, ccd.movconcepto,fv.tipofactura,desccomprobanteventa,fv.nrosucursal, fv.nrofactura,T.pendiente  

UNION 

SELECT concat(p2.apellido,', ', p2.nombres) elafiliado,   concat(p2.nrodoc, '-', p2.barra) nroafiliado,concat(fv.tipofactura,' ',desccomprobanteventa,' ',lpad(fv.nrosucursal,4,'0'),'-',lpad(fv.nrofactura,8,'0')) as comprobante, fv.fechaemision as emisionfactura,text_concatenar(concat('F. Emision:', orden.fechaemision, ' Orden: ',orden.nroorden,'-',orden.centro, '  Afiliado: ',p.nrodoc, '-', p.barra )) lasordenes,ccd.importe, ccd.saldo, ccd.movconcepto , case when nullvalue(T.pendiente) then 'no' else T.pendiente end ,text_concatenar( concat(ccdp.idpago,'-', ccdp.idcentropago)) elpago 
FROM persona p NATURAL JOIN consumo NATURAL JOIN orden NATURAL JOIN facturaorden fo JOIN facturaventa fv USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
JOIN tipocomprobanteventa tcv on (fv.tipocomprobante=tcv.idtipo) JOIN informefacturacion if USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
JOIN ctactedeudacliente ccd on (ccd.idcomprobante= (if.nroinforme*100)+if.idcentroinformefacturacion AND ccd.idcomprobantetipos=21 )
JOIN clientectacte ccc USING(idclientectacte)
JOIN persona p2 on (ccc.nrocliente=p2.nrodoc AND ccc.barra=p2.tipodoc)
LEFT JOIN ctactedeudapagocliente ccdp USING(iddeuda, idcentrodeuda)
LEFT JOIN (SELECT consumo.*,case when not nullvalue(orden.nroorden) THEN 'si' else 'no' END AS pendiente
FROM orden NATURAL JOIN consumo NATURAL JOIN cambioestadosorden
LEFT JOIN facturaorden fo USING(nroorden, centro)
WHERE idordenventaestadotipo= 1 AND nullvalue(fo.nrofactura) AND not (anulado) AND nullvalue(ceofechafin) AND tipo=56 and idasocconv=127 ) as T on(p2.nrodoc=T.nrodoc AND p2.tipodoc=T.tipodoc) 
WHERE fv.fechaemision >='2022-03-20' and orden.tipo=56 and nullvalue(fv.anulada) /* AND (fv.nrodoc='25725142'  or fv.nrodoc='13047676')*/
GROUP BY p2.apellido,p2.nombres,p2.nrodoc,p2.barra, fv.fechaemision,ccd.importe, ccd.saldo, ccd.movconcepto,fv.tipofactura,desccomprobanteventa,fv.nrosucursal, fv.nrofactura,T.pendiente );	
return ' ';
END;
$function$
