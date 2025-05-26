CREATE OR REPLACE FUNCTION public.tesoreria_reportedatospagos_opc_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
     rfiltros record;
     vuno date;
     vdos date;
    -- pfiltros varchar;
     vtres varchar;
     vcuatro varchar;	
	
BEGIN

        EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

        vuno = rfiltros.pfechadesde;
        vdos = rfiltros.pfechahasta;
        vtres = rfiltros.pidordenpagocontableestadotipo;
        vcuatro = rfiltros.pidordenpagotipo;


	CREATE TEMP TABLE temp_tesoreria_reportedatospagos_opc_contemporal 
	AS (
	SELECT CASE WHEN nullvalue(datosotp.fechaemision) AND nullvalue(opcminuta.fechaingreso) THEN lafacturacionacontrolar.fechaemision::varchar 
         WHEN nullvalue(lafacturacionacontrolar.fechaemision) AND nullvalue(datosotp.fechaemision) THEN opcminuta.fechaingreso::varchar 
        WHEN nullvalue(opcminuta.fechaingreso) AND nullvalue(lafacturacionacontrolar.fechaemision) THEN datosotp.fechaemision::varchar  END AS fechaemision
	, CASE WHEN nullvalue(lafacturacionacontrolar.nrocomprobante) AND nullvalue(opcminuta.nrocomprobante) THEN CONCAT(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' ,  to_char(nrofactura, '00000000')) 
        WHEN nullvalue(lafacturacionacontrolar.nrocomprobante) AND nullvalue(tipofactura) THEN opcminuta.nrocomprobante 
        WHEN nullvalue(opcminuta.nrocomprobante) AND nullvalue(tipofactura) THEN lafacturacionacontrolar.nrocomprobante END AS nrocomprobante
	,CASE WHEN nullvalue(lafacturacionacontrolar.importecomprobante)  AND nullvalue(opcminuta.nrocomprobante) THEN importeefectivo 
         WHEN nullvalue(lafacturacionacontrolar.nrocomprobante) AND nullvalue(tipofactura) THEN opcminuta.importetotal 
        WHEN nullvalue(opcminuta.nrocomprobante) AND nullvalue(tipofactura) THEN lafacturacionacontrolar.importecomprobante END AS importecomprobante
	,opcmontototal as importeopc
	,CONCAT(idordenpagocontable,'-',idcentroordenpagocontable) as elidordenpagocontable
        ,CASE WHEN nullvalue(lafacturacionacontrolar.numfactura) AND nullvalue(opcminuta.codprestamo) THEN elreintegro 
         WHEN nullvalue(lafacturacionacontrolar.numfactura) AND nullvalue(elreintegro) THEN CONCAT('Cod.Prestamo: ',codprestamo, ' Cod.Consumo:',nroconsumo)
        WHEN nullvalue(opcminuta.codprestamo) AND nullvalue(elreintegro) THEN lafacturacionacontrolar.numfactura END AS ids
        ,opcfechaingreso
	,case when nullvalue(datospago.popmonto) then 0 else datospago.popmonto end  as montopago
        ,case when nullvalue(valorescompensar.popmonto) then 0 else valorescompensar.popmonto end  as montovalorescompensar
	,datospago.popobservacion as tipoformapagodesc 
        ,ordenpagocontable.opcobservacion
	,ordenpagocontableestadotipo.opcetdescripcion
        ,CASE WHEN nullvalue(lafacturacionacontrolar.pdescripcion) AND nullvalue(opcminuta.beneficiario) THEN datosotp.denominacion 
         WHEN nullvalue(lafacturacionacontrolar.pdescripcion) AND nullvalue(denominacion) THEN opcminuta.beneficiario
        WHEN nullvalue(opcminuta.beneficiario) AND nullvalue(denominacion) THEN lafacturacionacontrolar.pdescripcion END AS titularopc
        ,idretencionprestador,descripretencion,rpmontototal
	,'1-Nro.Comprobante#nrocomprobante@2-Fecha Comp#fechaemision@3-Importe Comp.#importecomprobante@4-Titular#titularopc@5-OPC#elidordenpagocontable@6-Fecha OPC#opcfechaingreso@7-Obs. OPC#opcobservacion@8-Importe OPC#importeopc@9-Reintegro/Factura/Turismo#ids@10-Monto Pago#montopago@11-Forma Pago#tipoformapagodesc@12-Estado OPC#opcetdescripcion@13-Nro.Certificado#idretencionprestador@14-Reg. Retencion#descripretencion@15-$ Retenido#rpmontototal@16-$ Valores a Compensar#montovalorescompensar'::text as mapeocampocolumna
FROM ordenpagocontable JOIN ordenpagocontableestado using (idcentroordenpagocontable, idordenpagocontable) NATURAL JOIN ordenpagocontableestadotipo 
LEFT JOIN (SELECT idordenpagocontable, idcentroordenpagocontable, idordenpagotipo
	   FROM ordenpagocontableordenpago NATURAL JOIN ordenpago JOIN ordenpagotipo USING(idordenpagotipo)) 
           AS opcoptipo USING (idordenpagocontable, idcentroordenpagocontable)  
LEFT JOIN (SELECT idcentroordenpagocontable, idordenpagocontable, tipofactura,nrosucursal,nrofactura,CONCAT(nroreintegro,'-',anio,'-',idcentroregional) as elreintegro ,to_char(fechaemision,'DD/MM/YYYY') as fechaemision ,importeefectivo, denominacion 
	FROM ordenpagocontablereintegro NATURAL JOIN informefacturacionexpendioreintegro AS ifex JOIN informefacturacionestado USING (nroinforme, idcentroinformefacturacion)
	JOIN  informefacturacion AS if USING (nroinforme, idcentroinformefacturacion)
	LEFT JOIN  facturaventa AS fv USING (nrofactura, tipocomprobante, nrosucursal, tipofactura) JOIN cliente AS c ON(fv.nrodoc=c.nrocliente AND fv.barra=c.barra)
	WHERE nullvalue(fechafin) AND idinformefacturacionestadotipo<>5) AS datosotp USING(idcentroordenpagocontable, idordenpagocontable)
LEFT JOIN 
( 
SELECT idcentroordenpagocontable, idordenpagocontable ,text_concatenar(to_char(recepcion.fecha,'DD/MM/YYYY')) as fechaemision, CONCAT('Reg. ', text_concatenar(concat(rlf.numeroregistro, '-',  rlf.anio))) as nrocomprobante, prestador.pdescripcion, text_concatenar(rlf.obs), text_concatenar(rlf.numfactura) as numfactura	
,  sum(CASE WHEN rlf.idtipocomprobante = 4 THEN rlf.monto*-1 ELSE rlf.monto END) as importecomprobante 

FROM ordenpagocontablereclibrofact NATURAL JOIN reclibrofact AS rlf NATURAL JOIN recepcion NATURAL JOIN prestador  

GROUP BY idcentroordenpagocontable, idordenpagocontable, prestador.pdescripcion	
  			
) AS lafacturacionacontrolar
 USING (idcentroordenpagocontable, idordenpagocontable)

LEFT JOIN (
 SELECT idcentroordenpagocontable, idordenpagocontable, concat('MP: ', nroordenpago, '-', idcentroordenpago) as nrocomprobante, beneficiario, concepto, importetotal, fechaingreso,text_concatenar(concat(idconsumoturismo,'-',idcentroconsumoturismo)) as nroconsumo, text_concatenar(concat(idprestamo,'-',idcentroprestamo)) as codprestamo
FROM ordenpagocontableordenpago NATURAL JOIN ordenpago NATURAL JOIN consumoturismoordenpago NATURAL JOIN consumoturismo
        GROUP BY idordenpagocontable,idcentroordenpagocontable,nroordenpago,idcentroordenpago,nrocomprobante, beneficiario, concepto, importetotal, fechaingreso
) AS opcminuta USING (idcentroordenpagocontable, idordenpagocontable)

LEFT JOIN (SELECT sum(popmonto) AS popmonto, idordenpagocontable,idcentroordenpagocontable, text_concatenar(popobservacion) as popobservacion
	FROM pagoordenpagocontable
	WHERE idvalorescaja <>67 -- Para que no se vean las retenciones suss
                AND idvalorescaja <>65 -- Para que no se vean las retenciones ganancias 
                AND idvalorescaja <>80 -- Para que no se vean Valores a Compensar
        GROUP BY idordenpagocontable,idcentroordenpagocontable
                ) AS datospago USING(idordenpagocontable,idcentroordenpagocontable)

--KR 01-04-19 AGREGO las retenciones al reporte 
LEFT JOIN (SELECT sum(rpmontototal) as rpmontototal, text_concatenar( concat(idretencionprestador,' ') ) as idretencionprestador, text_concatenar( concat(rrdescripcion,'-',descripcionretencion)) as descripretencion,idordenpagocontable,idcentroordenpagocontable
           FROM retencionprestador JOIN tiporetencion on (retencionprestador.idtiporetencion=tiporetencion.idtiporetencion)
           NATURAL JOIN regimenretencion
           GROUP BY idordenpagocontable,idcentroordenpagocontable
                ) AS lasretenciones USING(idordenpagocontable,idcentroordenpagocontable)

--KR 18-05-23 AGREGO  Valores a Compensar como otra columna en FP tkt 5808
LEFT JOIN (SELECT sum(popmonto) AS popmonto, idordenpagocontable,idcentroordenpagocontable, text_concatenar(popobservacion) as popobservacion
	FROM pagoordenpagocontable
	WHERE idvalorescaja = 80 -- Para que se vean Valores a Compensar
        GROUP BY idordenpagocontable,idcentroordenpagocontable
                ) AS valorescompensar USING(idordenpagocontable,idcentroordenpagocontable)


--WHERE opcfechaingreso >='2017-08-01' AND nullvalue(opcfechafin)   AND  idordenpagocontable=3280
   WHERE opcfechaingreso >= vuno AND opcfechaingreso <= vdos AND nullvalue(opcfechafin) 
	AND  (idordenpagocontableestadotipo=vtres OR vtres::varchar='' OR nullvalue(vtres)) AND  (idordenpagotipo=vcuatro OR vcuatro::varchar='' OR nullvalue(vcuatro))

ORDER BY idordenpagocontable
);
    

RETURN 'true';
END;$function$
