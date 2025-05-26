CREATE OR REPLACE FUNCTION public.reintegros_informacionparacontrolreintegros_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        
	rfiltros record;
        
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_reintegros_informacionparacontrolreintegros_contemporal
AS (
	
select
crdescripcion,
concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' , to_char(nrofactura, '00000000')) AS nrofacturaconformato,fechaemision, importeefectivo as importeOT, CONCAT(idcentroregional, '-', nroreintegro, '-', anio) as elreintegro, concat(ro.nroorden, '-',ro.centro) as laorden,tipoprestaciondesc,tipoprestacion.nrocuentac, concat(cctipofactura , ' ' , ccpuntodeventa , '-' , to_char(ccnrocomprobante, '00000000')) as infocomprobante
,persona.barra,estadoreintegrodesc,fechaingreso,opcfechaingreso as fechapagoprobable,rfechaingreso,
tipoestadoreintegro,nroreintegro,anio,idcambioestado,ordenpago.nroordenpago,
persona.nrodoc,persona.tipodoc,reintegro.idcentroregional,rimporte,persona.apellido,persona.nombres,d.observacion
,concat('OPC',idordenpagocontable,'-',idcentroordenpagocontable) as idopc,opcmontototal as importeopc,popobservacion as observacionpago
,concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica,'-',pdescripcion) as codigopractica
,denominacionprestador
FROM reintegro
natural join centroregional
join persona using(tipodoc, nrodoc)
join restados USING (nroreintegro,anio,idcentroregional)
join tipoestadosreintegro USING(tipoestadoreintegro)
LEFT JOIN informefacturacionexpendioreintegro USING(nroreintegro,anio,idcentroregional)
LEFT JOIN informefacturacion USING(nroinforme,idcentroinformefacturacion)
LEFT JOIN reintegroprestacion USING(nroreintegro,anio,idcentroregional)
LEFT JOIN tipoprestacion USING(tipoprestacion)
LEFT JOIN reintegroorden as ro USING(nroreintegro,anio,idcentroregional)
LEFT JOIN catalogoordencomprobante USING(nroorden,centro)
LEFT JOIN catalogocomprobante USING (idcatalogocomprobante, idcentrocatalogocomprobante)
LEFT JOIN (SELECT idcatalogocomprobante, idcentrocatalogocomprobante,concat(idprestador,' - ',CASE WHEN nullvalue(pdescripcion) THEN pnombrefantasia ELSE pdescripcion END,' Cuit ',pcuit) as denominacionprestador 
           FROM prestador NATURAL JOIN catalogocomprobante 
           ) as prestadorcompro USING(idcatalogocomprobante, idcentrocatalogocomprobante)
LEFT JOIN itemvalorizada USING(nroorden,centro)
LEFT JOIN item USING(iditem,centro)
LEFT JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
LEFT join ordenpago using(nroordenpago,idcentroordenpago)
LEFT JOIN ordenpagocontablereintegro USING(nroreintegro,anio,idcentroregional)
LEFT JOIN ordenpagocontable USING(idordenpagocontable,idcentroordenpagocontable)
LEFT JOIN pagoordenpagocontable USING(idordenpagocontable,idcentroordenpagocontable)
left join tipoformapago on(reintegro.tipoformapago=tipoformapago.tipoformapago)
left JOIN (select nroreintegro,reintegroprestacion.idcentroregional,text_concatenar(observacion) as observacion
from reintegroprestacion group by nroreintegro,reintegroprestacion,idcentroregional
)as d using(nroreintegro,idcentroregional)
LEFT JOIN facturaventa USING(nrofactura,tipofactura,nrosucursal,tipocomprobante)
where nullvalue(refechafin)
AND (reintegro.rfechaingreso >= rfiltros.fechadesde ) and (reintegro.rfechaingreso <= rfiltros.fechahasta)
order by nroreintegro,anio,rfechaingreso


);
  

return true;
END;
$function$
