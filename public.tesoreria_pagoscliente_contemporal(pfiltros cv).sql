CREATE OR REPLACE FUNCTION public.tesoreria_pagoscliente_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE      	
	rfiltros record;
	
BEGIN 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_tesoreria_pagoscliente_contemporal
AS (
	SELECT cliente.nrocliente, case when nullvalue(persona.barra) then cliente.barra else persona.barra end as barra, fecharecibo::date, concat(idrecibo, '-', recibo.centro) as elrecibo, CASE WHEN NOT NULLVALUE(reanulado) THEN 'Anulado' END AS anulado, denominacion,monto, /*ccdc.movconcepto as motivodeuda, 
ccdc.idcomprobante::varchar as compdeuda*/
 text_concatenar(ccdc.movconcepto) as motivodeuda, 
text_concatenar(ccdc.idcomprobante)::varchar  as compdeuda

,valorescaja.descripcion,
/* concat(if.tipofactura, ' ', desccomprobanteventa,' ',if.nrosucursal,' - ', if.nrofactura) as nrofactura, facturaventa.fechaemision, 
CASE WHEN nullvalue(importeefectivo) then facturaventa.importectacte WHEN nullvalue(importectacte) THEN importeefectivo ELSE importeefectivo+importectacte END AS importefactura,login
*/
text_concatenar(concat(if.tipofactura, ' ', desccomprobanteventa,' ',if.nrosucursal,' - ', if.nrofactura)) as nrofactura,
text_concatenar( facturaventa.fechaemision), 
text_concatenar(CASE WHEN nullvalue(importeefectivo) then facturaventa.importectacte WHEN nullvalue(importectacte) THEN importeefectivo ELSE importeefectivo+importectacte END )AS importefactura,login
 
,'1-Nro.Cliente#nrocliente@2-Barra#barra@3-Nrofactura#nrofactura@4-F.Emision#fechaemision@5-$ Comprobante#importefactura@6-F.Recibo#fecharecibo@7-Nro. Recibo#elrecibo@8-F.Pago#descripcion@9-Estado Recibo#anulado@10-Cliente#denominacion@11-Importe Recibo#monto@12-Concepto Deuda#motivodeuda@13-Usuario#login'::text as mapeocampocolumna

	FROM ctactepagocliente JOIN recibo ON (idcomprobante= idrecibo AND idcentropago= centro) 
NATURAL JOIN recibocupon 
NATURAL JOIN recibousuario
 JOIN usuario on(usuario.idusuario=recibousuario.idusuario)
        NATURAL JOIN valorescaja
	NATURAL JOIN clientectacte NATURAL JOIN cliente
        LEFT JOIN persona ON nrocliente= nrodoc AND cliente.barra=persona.tipodoc
	LEFT JOIN ctactedeudapagocliente USING (idpago, idcentropago) LEFT JOIN ctactedeudacliente AS ccdc USING(iddeuda, idcentrodeuda) LEFT JOIN informefacturacion if ON ccdc.idcomprobante=if.nroinforme*100+if.idcentroinformefacturacion LEFT JOIN tipocomprobanteventa ON tipocomprobante= idtipo left JOIN facturaventa USING(tipofactura,tipocomprobante,nrosucursal,nrofactura)
        LEFT JOIN informefacturacionestado USING(nroinforme, idcentroinformefacturacion)
  	WHERE fecharecibo >=rfiltros.fechadesde AND fecharecibo <=rfiltros.fechahasta AND nullvalue(fechafin) and recibo.centro=rfiltros.idcentroregional
group by cliente.nrocliente,persona.barra,cliente.barra,fecharecibo , elrecibo,anulado,denominacion, 	monto, 
valorescaja.descripcion,/*  nrofactura,if.tipofactura,desccomprobanteventa,if.nrosucursal, facturaventa.fechaemision,importefactura,*/login

	UNION

SELECT persona.nrodoc as nrocliente, persona.barra, fecharecibo::date, concat(idrecibo, '-', recibo.centro) as elrecibo, CASE WHEN NOT NULLVALUE(reanulado) THEN 'Anulado' END AS anulado,  concat(persona.apellido,', ', persona.nombres) as denominacion,  	monto, /*ccdc.movconcepto as motivodeuda, ccdc.idcomprobante::varchar as compdeuda*/
 text_concatenar(ccdc.movconcepto) as motivodeuda, 
text_concatenar(ccdc.idcomprobante)::varchar  as compdeuda

,valorescaja.descripcion, 
/*concat(if.tipofactura, ' ', desccomprobanteventa,' ',if.nrosucursal,' - ', if.nrofactura) as nrofactura, facturaventa.fechaemision, 
CASE WHEN nullvalue(importeefectivo) then facturaventa.importectacte WHEN nullvalue(importectacte) THEN importeefectivo ELSE importeefectivo+importectacte END AS importefactura,login*/
text_concatenar(concat(if.tipofactura, ' ', desccomprobanteventa,' ',if.nrosucursal,' - ', if.nrofactura)) as nrofactura,
text_concatenar( facturaventa.fechaemision), 
text_concatenar(CASE WHEN nullvalue(importeefectivo) then facturaventa.importectacte WHEN nullvalue(importectacte) THEN importeefectivo ELSE importeefectivo+importectacte END )AS importefactura,login
 

,'1-Nro.Cliente#nrocliente@2-Barra#barra@3-Nrofactura#nrofactura@4-F.Emision#fechaemision@5-$ Comprobante#importefactura@6-F.Recibo#fecharecibo@7-Nro. Recibo#elrecibo@8-F.Pago#descripcion@9-Estado Recibo#anulado@10-Cliente#denominacion@11-Importe Recibo#monto@12-Concepto Deuda#motivodeuda@13-Usuario#login'::text as mapeocampocolumna
 
	FROM cuentacorrientepagos JOIN recibo ON (idcomprobante= idrecibo AND idcentropago= centro) 
NATURAL JOIN persona   NATURAL JOIN recibocupon  
NATURAL JOIN recibousuario
JOIN usuario on(usuario.idusuario=recibousuario.idusuario)
NATURAL JOIN valorescaja
	LEFT JOIN cuentacorrientedeudapago USING (idpago, idcentropago)        LEFT JOIN cuentacorrientedeuda  AS ccdc USING(iddeuda, idcentrodeuda) 
 LEFT JOIN informefacturacion if ON ccdc.idcomprobante=if.nroinforme*100+if.idcentroinformefacturacion LEFT JOIN tipocomprobanteventa ON tipocomprobante= idtipo JOIN facturaventa USING(tipofactura,tipocomprobante,nrosucursal,nrofactura)  LEFT JOIN informefacturacionestado USING(nroinforme, idcentroinformefacturacion)
	WHERE fecharecibo >=rfiltros.fechadesde AND fecharecibo <=rfiltros.fechahasta AND nullvalue(fechafin) and recibo.centro=rfiltros.idcentroregional
group by persona.nrodoc,persona.barra, fecharecibo , elrecibo,anulado,denominacion, 	monto, 
valorescaja.descripcion, /* nrofactura,if.tipofactura,desccomprobanteventa,if.nrosucursal, facturaventa.fechaemision,importefactura,*/login


/*Dani agrego el 29052021 para que se visualizen los recibos de turismo*/

union
 SELECT  
persona.nrodoc  as nrocliente, 
persona.barra,
 fecharecibo::date, concat(recibo.idrecibo, '-', recibo.centro) as elrecibo, CASE WHEN NOT NULLVALUE(reanulado) THEN 'Anulado' END AS anulado,
  concat(persona.apellido,', ', persona.nombres) as denominacion,  
	monto, 
text_concatenar(ccdc.movconcepto)::varchar as motivodeuda, 
text_concatenar(ccdc.idcomprobante)::varchar as compdeuda,
valorescaja.descripcion,
/* concat(if.tipofactura, ' ', desccomprobanteventa,' ',if.nrosucursal,' - ', if.nrofactura) as nrofactura, facturaventa.fechaemision, 
CASE WHEN nullvalue(importeefectivo) then facturaventa.importectacte WHEN nullvalue(importectacte) THEN importeefectivo ELSE importeefectivo+importectacte END AS importefactura,login*/
text_concatenar(concat(if.tipofactura, ' ', desccomprobanteventa,' ',if.nrosucursal,' - ', if.nrofactura)) as nrofactura,
text_concatenar( facturaventa.fechaemision), 
text_concatenar(CASE WHEN nullvalue(importeefectivo) then facturaventa.importectacte WHEN nullvalue(importectacte) THEN importeefectivo ELSE importeefectivo+importectacte END )AS importefactura,login
 
,'1-Nro.Cliente#nrocliente@2-Barra#barra@3-Nrofactura#nrofactura@4-F.Emision#fechaemision@5-$ Comprobante#importefactura@6-F.Recibo#fecharecibo@7-Nro. Recibo#elrecibo@8-F.Pago#descripcion@9-Estado Recibo#anulado@10-Cliente#denominacion@11-Importe Recibo#monto@12-Concepto Deuda#motivodeuda@13-Usuario#login'::text as mapeocampocolumna



 FROM cuentacorrientepagos JOIN recibo ON (idcomprobante= idrecibo AND idcentropago= centro) 
NATURAL JOIN persona   NATURAL JOIN recibocupon  
NATURAL JOIN recibousuario
JOIN usuario on(usuario.idusuario=recibousuario.idusuario)
NATURAL JOIN valorescaja
	LEFT JOIN cuentacorrientedeudapago USING (idpago, idcentropago)        LEFT JOIN cuentacorrientedeuda  AS ccdc USING(iddeuda, idcentrodeuda) 
 LEFT JOIN informefacturacion if ON ccdc.idcomprobante=if.nroinforme*100+if.idcentroinformefacturacion LEFT JOIN tipocomprobanteventa ON tipocomprobante= idtipo
left  JOIN facturaventa USING(tipofactura,tipocomprobante,nrosucursal,nrofactura)  
left   JOIN informefacturacionestado USING(nroinforme, idcentroinformefacturacion)

	
WHERE 
fecharecibo >=rfiltros.fechadesde AND fecharecibo <=rfiltros.fechahasta AND nullvalue(fechafin)
and ((idinformefacturacionestadotipo<>5  AND nullvalue(fechafin)) or (nullvalue(if.nroinforme)))
	and cuentacorrientepagos.movconcepto ilike '%turismo%' and recibo.centro=rfiltros.idcentroregional
--fecharecibo >='2021-04-01' AND fecharecibo <='2021-04-30' AND nullvalue(fechafin)


group by nrocliente,persona.barra,fecharecibo , elrecibo, persona.nrodoc,anulado,denominacion, 	monto, 
valorescaja.descripcion,/*  nrofactura,if.tipofactura,desccomprobanteventa,if.nrosucursal, facturaventa.fechaemision,importefactura,*/login





);
     

return true;
END;
$function$
