CREATE OR REPLACE FUNCTION public.tesoreria_reportedaospagos_opc(date, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	pfechadesde alias for $1;
	pfechahasta alias for $2;
	
	
BEGIN
IF iftableexists('tablareporteentrefechas') THEN
	DROP TABLE tablareporteentrefechas;
END IF;
IF iftableexists('tablareporteentrefechas_titulos') THEN
	DROP TABLE tablareporteentrefechas_titulos;
END IF;

CREATE TEMP TABLE tablareporteentrefechas_titulos(fechaemision varchar,nrocomprobante varchar, importecomprobante varchar,importeopc varchar, elidordenpagocontable varchar, opcobservacion VARCHAR, elreintegro varchar, montopago varchar,tipoformapagodesc varchar);
INSERT INTO tablareporteentrefechas_titulos(fechaemision,nrocomprobante,importecomprobante,importeopc,opcobservacion, elidordenpagocontable,elreintegro,montopago,tipoformapagodesc) 
VALUES( '1-Fecha Comp.','2-Nro.Comp.','3-Importe Comp.','4-OPC','5-Obs. OPC','6-Importe OPC','7-Reintegro', '8-Monto Pago','9-Forma Pago');

 

CREATE TEMP TABLE tablareporteentrefechas as (
SELECT to_char(fechaemision,'DD/MM/YYYY')  as fechaemision
	,CONCAT(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' ,  to_char(nrofactura, '00000000')) AS nrocomprobante
	,importeefectivo AS importecomprobante
	,opcmontototal as importeopc
	,CONCAT(idordenpagocontable,'-',idcentroordenpagocontable) as elidordenpagocontable
	,CONCAT(nroreintegro,'-',anio,'-',idcentroregional) as elreintegro
	,case when nullvalue(datospago.popmonto) then 0 else datospago.popmonto end  as montopago
	,datospago.popobservacion as tipoformapagodesc 
        ,ordenpagocontable.opcobservacion
	
FROM ordenpagocontable JOIN ordenpagocontablereintegro USING (idcentroordenpagocontable, idordenpagocontable)
JOIN ordenpagocontableestado using (idcentroordenpagocontable, idordenpagocontable)
LEFT JOIN (SELECT tipofactura,nrosucursal,nrofactura,nroreintegro, anio, idcentroregional,fechaemision,importeefectivo
	FROM informefacturacionexpendioreintegro AS ifex JOIN informefacturacionestado USING (nroinforme, idcentroinformefacturacion)
	JOIN  informefacturacion AS if USING (nroinforme, idcentroinformefacturacion)
	LEFT JOIN  facturaventa AS fv USING (nrofactura, tipocomprobante, nrosucursal, tipofactura)
	WHERE nullvalue(fechafin) AND 	idinformefacturacionestadotipo<>5) AS datosotp USING(nroreintegro, anio, idcentroregional)

LEFT JOIN (SELECT * 
	FROM pagoordenpagocontable
	WHERE idvalorescaja <>67 -- Para que no se vean las retenciones suss
                AND idvalorescaja <>65 -- Para que no se vean las retenciones ganancias
                ) AS datospago USING(idordenpagocontable,idcentroordenpagocontable)

--WHERE opcfechaingreso >='2017-08-01' AND nullvalue(opcfechafin)   AND  idordenpagocontable=3280
   WHERE opcfechaingreso >= pfechadesde AND opcfechaingreso <= pfechahasta AND nullvalue(opcfechafin) 
		AND  idordenpagocontableestadotipo<>6   --No tenga en cuenta las anuladas
              
ORDER BY idpagoordenpagocontable);
	
RETURN 'true';
END;
$function$
