CREATE OR REPLACE FUNCTION public.estadisticas_informeeconomico_alta(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE

--RECORD
  rfiltros RECORD;
  relem RECORD;
  
--CURSORES
  cursorarchi REFCURSOR;
 

--VARIABLES
  ptipoarchivo VARCHAR; 
  respuesta varchar;
  contenido varchar;
  separador varchar;
  encabezado varchar;
  nombrearchivo varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  idarchivo BIGINT;
  rusuario RECORD;
  vfechageneracion DATE;
  vpadronactivosal TIMESTAMP;
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;



INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienaclavenovedad,ienafechanovedad) (
select ienasigno,fechaperiodo,importectacte as importe,0.0 as lopagado,0.0 as deuda,'ingreso unco'::text as tipomovimiento,concat('Comprobante ',tipofactura,nrosucursal,'-',nrofactura,' Items: ',detalle) as detalle,ienaclavenovedad,ienafechanovedad
from (
select DATE_TRUNC('month',fechaemision) as fechaperiodo,fechaemision as ienafechanovedad,concat(tipocomprobante,'|',nrosucursal,'|',nrofactura,'|',centro,'|',tipofactura) as ienaclavenovedad ,text_concatenar(concat(idconcepto,'-',descripcion)) as detalle
,sum(case when tipofactura = 'NC' THEN importe*-1 ELSE importe end) as sumaitems
,min(case when tipofactura = 'NC' THEN importectacte*-1 else importectacte end ) as importectacte,tipocomprobante,nrosucursal,nrofactura,centro,tipofactura, case when tipofactura = 'NC' THEN -1 ELSE 1 end as ienasigno
from facturaventa 
natural join itemfacturaventa 
where nrodoc = 8 and tipodoc = 500 and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta and centro = 1 and nullvalue(anulada)
group by tipocomprobante,nrosucursal,nrofactura,centro,tipofactura
) as t 
order by fechaperiodo
);

INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienafechanovedad,ienaclavenovedad) (
select case when tipofactura = 'NC' THEN -1 ELSE 1 end as ienasigno,DATE_TRUNC('month',fechaemision) as fechaperiodo,
case when tipofactura = 'NC' THEN (importeefectivo + importedebito +	importecredito + importectacte	) *-1 else (importeefectivo + importedebito +	importecredito + importectacte	) end  as importe,0.0 as lopagado,0.0 as deuda
,'ingreso central' as tipomovimiento,concat('Cant.Comprobantes ', 1) as detalle
,fechaemision as ienafechanovedad,concat(tipocomprobante,'|',nrosucursal,'|',nrofactura,'|',centro,'|',tipofactura) as ienaclavenovedad
from facturaventa 
where nrodoc <> 8 and tipodoc <> 500 and (tipofactura = 'FA' or tipofactura = 'NC' ) and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta and centro = 1 and nullvalue(anulada)
);


INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienafechanovedad,ienaclavenovedad) (
select case when tipofactura = 'NC' THEN -1 ELSE 1 end as ienasigno,DATE_TRUNC('month',fechaemision) as fechaperiodo,
case when tipofactura = 'NC' THEN (importeefectivo + importedebito +	importecredito + importectacte	) *-1 else (importeefectivo + importedebito +	importecredito + importectacte	) end  as importe,0.0 as lopagado,0.0 as deuda
,'ingreso farmacia' as tipomovimiento,concat('Cant.Comprobantes ', 1) as detalle
,fechaemision as ienafechanovedad,concat(tipocomprobante,'|',nrosucursal,'|',nrofactura,'|',centro,'|',tipofactura) as ienaclavenovedad
from facturaventa 
where  (tipofactura = 'FA' or tipofactura = 'NC' ) and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta and centro = 99 and nullvalue(anulada)
);



INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienafechanovedad,ienaclavenovedad) (
select case when tipofactura = 'NC' THEN -1 ELSE 1 end as ienasigno,DATE_TRUNC('month',fechaemision) as fechaperiodo,
case when tipofactura = 'NC' THEN (importeefectivo + importedebito +	importecredito + importectacte	) *-1 else (importeefectivo + importedebito +	importecredito + importectacte	) end  as importe,0.0 as lopagado,0.0 as deuda
,'ingreso delegaciones' as tipomovimiento,concat('Cant.Comprobantes ', 1) as detalle
,fechaemision as ienafechanovedad,concat(tipocomprobante,'|',nrosucursal,'|',nrofactura,'|',centro,'|',tipofactura) as ienaclavenovedad
from facturaventa 
where  (tipofactura = 'FA' or tipofactura = 'NC' ) and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta and centro <> 99 AND centro <> 1 and nullvalue(anulada)
);


INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienafechanovedad,ienaclavenovedad) (

select -1 as ienasigno,DATE_TRUNC('month',fechaemision) as fechaperiodo,sum(importe) as importe,0.0 as lopagado,0.0 as deuda,concat('Egresos ',descripcion) as tipomovimiento,concat('Cantidad Sub.',count(nrodoc))::text as detalle
,fechaemision as ienafechanovedad,concat(nroorden,'|',centro,'|',tipo) as ienaclavenovedad
from orden 
natural join consumo 
natural join ordvalorizada
natural join itemvalorizada
natural join item as i
join reintegro_configuraemisionautomatica as ca ON itemvalorizada.idplancovertura = ca.idplancoberturas_expendio 
                                               AND i.idpractica = ca.idpractica AND ca.idnomenclador= i.idnomenclador
                                               AND i.idcapitulo = ca.idcapitulo AND ca.idsubcapitulo= i.idsubcapitulo
JOIN plancobertura as p ON ca.idplancoberturas = p.idplancoberturas 
where tipo = 55 and not anulado and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta
GROUP BY centro,nroorden,tipo,fechaemision,descripcion
ORDER BY fechaperiodo,tipomovimiento
);



INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienafechanovedad,ienaclavenovedad) (
select -1 as ienasigno,DATE_TRUNC('month',fechaemision) as fechaperiodo,sum(importe) as importe,0.0 as lopagado,0.0 as deuda,concat('Egresos ','Reintegros') as tipomovimiento,concat('Cantidad Reintegros.',text_concatenarsinrepetir(p.descripcion))::text as detalle
,fechaemision as ienafechanovedad,concat(nroorden,'|',centro,'|',tipo) as ienaclavenovedad
from orden 
natural join consumo 
natural join ordvalorizada
natural join itemvalorizada
natural join item as i
join reintegro_configuraemisionautomatica as ca ON i.idpractica <> ca.idpractica AND ca.idnomenclador <> i.idnomenclador
                                               AND i.idcapitulo <> ca.idcapitulo AND ca.idsubcapitulo <> i.idsubcapitulo
JOIN plancobertura as p ON itemvalorizada.idplancovertura = p.idplancoberturas 
where tipo = 55 and not anulado and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta
GROUP BY centro,nroorden,tipo,fechaemision,descripcion
ORDER BY fechaperiodo,tipomovimiento
);

-- egresos farmacia

--

INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienafechanovedad,ienaclavenovedad) (
SELECT min(signo) as ienasigno,fechaperiodo,sum(monto) as importe,sum(lopagado) as lopagado,sum(deuda) as deuda,tipomovimiento,text_concatenarsinrepetir(detalle) as detalle
,fechaemision as ienafechanovedad,concat(anio,'|',numeroregistro,'|',tipomovimiento) as ienaclavenovedad
from (
SELECT CASE WHEN tipofactura ilike 'NC' THEN 1 ELSE -1 end as signo,DATE_TRUNC('month',fechaemision) as fechaperiodo,concat('Nro.registro: ',rlf.numeroregistro,'-', rlf.anio,' Prestador: ',prestador.pdescripcion,' F.Emision: ',to_char(rlf.fechaemision,'DD-MM-YYYY'),'Nro.Factura ',tipofactura,' ',clase,' ',numfactura) as detalle,  rlf.monto, rlf.fechaemision, case when nullvalue(montopagado) then 0 else montopagado end AS lopagado,monto - case when nullvalue(montopagado) then 0 else montopagado end as deuda,  concat('Egreso ',descripcionsiges) as tipomovimiento,rlf.numeroregistro,rlf.anio
	FROM recepcion 
        NATURAL JOIN reclibrofact as rlf
        JOIN tipocomprobante USING(idtipocomprobante) 
        join prestador USING (idprestador) 
        join  prestadorconfig USING (idprestador) 
        JOIN multivac.mapeocatgasto  ON (rlf.catgasto=multivac.mapeocatgasto.idcategoriagastosiges)	
        LEFT JOIN  ordenpagocontablereclibrofact  AS opcrlf USING(numeroregistro,anio)  
        LEFT JOIN ordenpagocontable USING (idordenpagocontable,idcentroordenpagocontable) 
	LEFT  JOIN ordenpagocontableestado USING (idordenpagocontable,idcentroordenpagocontable) 
	WHERE nullvalue(opcfechafin) and (idordenpagocontableestadotipo <> 6 OR nullvalue(idordenpagocontableestadotipo)) AND rlf.catgasto = 57 AND rlf.fechaemision >= rfiltros.fechadesde
	AND rlf.fechaemision <=rfiltros.fechahasta
) as t
group by numeroregistro,anio,tipomovimiento,fechaperiodo,fechaemision
ORDER BY fechaperiodo
);

-- otros gastos 
INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienafechanovedad,ienaclavenovedad) (
SELECT min(signo) as ienasigno,fechaperiodo,sum(monto) as importe,sum(lopagado) as lopagado,sum(deuda) as deuda,tipomovimiento,text_concatenarsinrepetir(detalle) as detalle
,fechaemision as ienafechanovedad,concat(anio,'|',numeroregistro,'|',tipomovimiento) as ienaclavenovedad
from (
SELECT CASE WHEN tipofactura ilike 'NC' THEN 1 ELSE -1 end as signo,DATE_TRUNC('month',fechaemision) as fechaperiodo,concat('Nro.registro: ',rlf.numeroregistro,'-', rlf.anio,' Prestador: ',prestador.pdescripcion,' F.Emision: ',to_char(rlf.fechaemision,'DD-MM-YYYY'),'Nro.Factura ',tipofactura,' ',clase,' ',numfactura,' Cat.Gasto: ',descripcionsiges) as detalle
,  rlf.monto, rlf.fechaemision, case when nullvalue(montopagado) then 0 else montopagado end AS lopagado
,monto - case when nullvalue(montopagado) then 0 else montopagado end as deuda
,  concat('Egreso ','gs. funcionamiento') as tipomovimiento,rlf.numeroregistro,rlf.anio
	FROM recepcion 
        NATURAL JOIN reclibrofact as rlf
        JOIN tipocomprobante USING(idtipocomprobante) 
        join prestador USING (idprestador) 
        join  prestadorconfig USING (idprestador) 
        JOIN multivac.mapeocatgasto  ON (rlf.catgasto=multivac.mapeocatgasto.idcategoriagastosiges)	
        LEFT JOIN  ordenpagocontablereclibrofact  AS opcrlf USING(numeroregistro,anio)  
        LEFT JOIN ordenpagocontable USING (idordenpagocontable,idcentroordenpagocontable) 
	LEFT  JOIN ordenpagocontableestado USING (idordenpagocontable,idcentroordenpagocontable) 
	WHERE nullvalue(opcfechafin) and (idordenpagocontableestadotipo <> 6 OR nullvalue(idordenpagocontableestadotipo)) AND rlf.catgasto <> 57 AND rlf.catgasto <> 4 AND rlf.fechaemision >= rfiltros.fechadesde
	AND rlf.fechaemision <=rfiltros.fechahasta
) as t
group by numeroregistro,anio,tipomovimiento,fechaperiodo,fechaemision
ORDER BY fechaperiodo
);


-- prestaciones medicas
---


INSERT INTO ienovedad_alta (ienasigno,ienafechaperiodo,ienaimporte,ienalopagado,ienadeuda,novedadtipo,ienadetalle,ienafechanovedad,ienaclavenovedad) (
SELECT min(signo) as ienasigno,fechaperiodo,sum(monto) as importe,sum(lopagado) as lopagado,sum(deuda) as deuda,tipomovimiento,text_concatenarsinrepetir(detalle) as detalle
,fechaemision as ienafechanovedad,concat(anio,'|',numeroregistro,'|',tipomovimiento) as ienaclavenovedad
from (
SELECT CASE WHEN tipofactura ilike 'NC' THEN 1 ELSE -1 end as signo,DATE_TRUNC('month',fechaemision) as fechaperiodo,concat('Nro.registro: ',rlf.numeroregistro,'-', rlf.anio,' Prestador: ',prestador.pdescripcion,' F.Emision: ',to_char(rlf.fechaemision,'DD-MM-YYYY'),' Cat.Gasto: ',descripcionsiges,'Nro.Factura ',tipofactura,' ',clase,' ',numfactura) as detalle
,  rlf.monto, rlf.fechaemision, case when nullvalue(montopagado) then 0 else montopagado end AS lopagado,monto - case when nullvalue(montopagado) then 0 else montopagado end as deuda
,  concat('Egreso ','prestaciones medica') as tipomovimiento,rlf.numeroregistro,rlf.anio
	FROM recepcion 
        NATURAL JOIN reclibrofact as rlf
        JOIN tipocomprobante USING(idtipocomprobante) 
        join prestador USING (idprestador) 
        join  prestadorconfig USING (idprestador) 
        JOIN multivac.mapeocatgasto  ON (rlf.catgasto=multivac.mapeocatgasto.idcategoriagastosiges)	
        LEFT JOIN  ordenpagocontablereclibrofact  AS opcrlf USING(numeroregistro,anio)  
        LEFT JOIN ordenpagocontable USING (idordenpagocontable,idcentroordenpagocontable) 
	LEFT  JOIN ordenpagocontableestado USING (idordenpagocontable,idcentroordenpagocontable) 
	WHERE nullvalue(opcfechafin) and (idordenpagocontableestadotipo <> 6 OR nullvalue(idordenpagocontableestadotipo)) AND rlf.catgasto = 4 
	AND rlf.fechaemision >= rfiltros.fechadesde AND rlf.fechaemision <=rfiltros.fechahasta
) as t
group by numeroregistro,anio,tipomovimiento,fechaperiodo,fechaemision
ORDER BY fechaperiodo
);



respuesta = 'oki';


return respuesta;
END;
$function$
