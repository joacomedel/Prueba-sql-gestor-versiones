CREATE OR REPLACE FUNCTION public.estadisticas_informeeconomico(pfiltros character varying)
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

create temp table informe_economico as (
select 1 as signo,fechaperiodo,sum(importectacte) as importe,0.0 as lopagado,0.0 as deuda,'ingreso unco'::text as tipomovimiento,text_concatenar(concat('Comprobante ',tipofactura,nrosucursal,'-',nrofactura,' Items: ',detalle)) as detalle
from (
select DATE_TRUNC('month',fechaemision) as fechaperiodo,text_concatenar(concat(idconcepto,'-',descripcion)) as detalle,sum(case when tipofactura = 'NC' THEN importe*-1 ELSE importe end) as sumaitems,min(case when tipofactura = 'NC' THEN importectacte*-1 else importectacte end ) as importectacte,tipocomprobante,nrosucursal,nrofactura,centro,tipofactura 
from facturaventa 
natural join itemfacturaventa 
where nrodoc = 8 and tipodoc = 500 and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta and centro = 1 and nullvalue(anulada)
group by tipocomprobante,nrosucursal,nrofactura,centro,tipofactura
) as t 
group by fechaperiodo
order by fechaperiodo
);

INSERT INTO informe_economico (fechaperiodo,tipomovimiento,detalle,importe,lopagado,deuda) (
select DATE_TRUNC('month',fechaemision) as fechaperiodo,'ingreso central' as tipomovimiento,concat('Cant.Comprobantes ', count(nrofactura)) as detalle,sum(case when tipofactura = 'NC' THEN (importeefectivo + importedebito +	importecredito + importectacte	) *-1 else (importeefectivo + importedebito +	importecredito + importectacte	) end ) as importe,0.0 as lopagado,0.0 as deuda
from facturaventa 
where nrodoc <> 8 and tipodoc <> 500 and (tipofactura = 'FA' or tipofactura = 'NC' ) and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta and centro = 1 and nullvalue(anulada)
group by fechaperiodo
);

INSERT INTO informe_economico (fechaperiodo,tipomovimiento,detalle,importe,lopagado,deuda) (
select DATE_TRUNC('month',fechaemision) as fechaperiodo,'ingreso farmacia' as tipomovimiento,concat('Cant.Comprobantes ', count(nrofactura)) as detalle,sum(case when tipofactura = 'NC' THEN (importeefectivo + importedebito +	importecredito + importectacte	) *-1 else (importeefectivo + importedebito +	importecredito + importectacte	) end ) as importe,0.0 as lopagado,0.0 as deuda
from facturaventa 
where  (tipofactura = 'FA' or tipofactura = 'NC' ) and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta  and centro = 99 and nullvalue(anulada)
group by fechaperiodo
);

INSERT INTO informe_economico (fechaperiodo,tipomovimiento,detalle,importe,lopagado,deuda) (
select DATE_TRUNC('month',fechaemision) as fechaperiodo,'ingreso delegaciones' as tipomovimiento,concat('Cant.Comprobantes ', count(nrofactura)) as detalle,sum(case when tipofactura = 'NC' THEN (importeefectivo + importedebito +	importecredito + importectacte	) *-1 else (importeefectivo + importedebito +	importecredito + importectacte	) end ) as importe,0.0 as lopagado,0.0 as deuda
from facturaventa 
where  (tipofactura = 'FA' or tipofactura = 'NC' ) and fechaemision >= '2020-01-01' and centro <> 99 AND centro <> 1 and nullvalue(anulada)
group by fechaperiodo
);

INSERT INTO informe_economico (fechaperiodo,importe,lopagado,deuda,tipomovimiento,detalle) (
select DATE_TRUNC('month',fechaemision) as fechaperiodo,sum(importe) as importe,0.0 as lopagado,0.0 as deuda,concat('Egresos ',descripcion) as tipomovimiento,concat('Cantidad Sub.',count(nrodoc))::text as detalle
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
GROUP BY fechaperiodo,tipomovimiento
ORDER BY fechaperiodo,tipomovimiento
);


INSERT INTO informe_economico (fechaperiodo,importe,lopagado,deuda,tipomovimiento,detalle) (
select DATE_TRUNC('month',fechaemision) as fechaperiodo,sum(importe) as importe,0.0 as lopagado,0.0 as deuda,concat('Egresos Reintegros') as tipomovimiento,concat('Cantidad Reintegros.',count(nrodoc), ' por ',text_concatenarsinrepetir(p.descripcion))::text as detalle
from orden 
natural join consumo 
natural join ordvalorizada
natural join itemvalorizada
natural join item as i
join reintegro_configuraemisionautomatica as ca ON i.idpractica <> ca.idpractica AND ca.idnomenclador <> i.idnomenclador
                                               AND i.idcapitulo <> ca.idcapitulo AND ca.idsubcapitulo <> i.idsubcapitulo
JOIN plancobertura as p ON itemvalorizada.idplancovertura = p.idplancoberturas 
where tipo = 55 and not anulado and fechaemision >=rfiltros.fechadesde and fechaemision <= rfiltros.fechahasta
GROUP BY fechaperiodo,tipomovimiento
ORDER BY fechaperiodo,tipomovimiento
);

-- egresos farmacia

INSERT INTO informe_economico (fechaperiodo,importe,lopagado,deuda,tipomovimiento,detalle) (
SELECT fechaperiodo,sum(monto) as importe,sum(lopagado) as lopagado,sum(deuda) as deuda,tipomovimiento,text_concatenarsinrepetir(detalle) as detalle
from (
SELECT DATE_TRUNC('month',fechaemision) as fechaperiodo,concat('Nro.registro: ',rlf.numeroregistro,'-', rlf.anio,' Prestador: ',prestador.pdescripcion,' F.Emision: ',to_char(rlf.fechaemision,'DD-MM-YYYY')) as detalle,  rlf.monto, rlf.fechaemision, case when nullvalue(montopagado) then 0 else montopagado end AS lopagado,monto - case when nullvalue(montopagado) then 0 else montopagado end as deuda,  concat('egreso ',descripcionsiges) as tipomovimiento
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
group by fechaperiodo,tipomovimiento
ORDER BY fechaperiodo
);

-- otros gastos 
INSERT INTO informe_economico (fechaperiodo,importe,lopagado,deuda,tipomovimiento,detalle) (
SELECT fechaperiodo,sum(monto) as importe,sum(lopagado) as lopagado,sum(deuda) as deuda,tipomovimiento,text_concatenarsinrepetir(detalle) as detalle
from (
SELECT DATE_TRUNC('month',fechaemision) as fechaperiodo,concat('Nro.registro: ',rlf.numeroregistro,'-', rlf.anio,' Prestador: ',prestador.pdescripcion,' F.Emision: ',to_char(rlf.fechaemision,'DD-MM-YYYY'),' Cat.Gasto: ',descripcionsiges) as detalle,  rlf.monto, rlf.fechaemision, case when nullvalue(montopagado) then 0 else montopagado end AS lopagado,monto - case when nullvalue(montopagado) then 0 else montopagado end as deuda,  concat('egreso gs. funcionamiento') as tipomovimiento
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
group by fechaperiodo,tipomovimiento
ORDER BY fechaperiodo
);

-- prestaciones medicas
INSERT INTO informe_economico (fechaperiodo,importe,lopagado,deuda,tipomovimiento,detalle) (
SELECT fechaperiodo,sum(monto) as importe,sum(lopagado) as lopagado,sum(deuda) as deuda,tipomovimiento,text_concatenarsinrepetir(detalle) as detalle
from (
SELECT DATE_TRUNC('month',fechaemision) as fechaperiodo,concat('Nro.registro: ',rlf.numeroregistro,'-', rlf.anio,' Prestador: ',prestador.pdescripcion,' F.Emision: ',to_char(rlf.fechaemision,'DD-MM-YYYY'),' Cat.Gasto: ',descripcionsiges) as detalle,  rlf.monto , rlf.fechaemision, case when nullvalue(montopagado) then 0 else montopagado end  + case when nullvalue(importedebito) then 0 else importedebito end AS lopagado ,monto - (case when nullvalue(montopagado) then 0 else montopagado end + case when nullvalue(importedebito) then 0 else importedebito end ) as deuda,  concat('egreso prestaciones medica') as tipomovimiento
	FROM recepcion 
        NATURAL JOIN reclibrofact as rlf
        JOIN tipocomprobante USING(idtipocomprobante) 
        join prestador USING (idprestador) 
        join  prestadorconfig USING (idprestador) 
        JOIN multivac.mapeocatgasto  ON (rlf.catgasto=multivac.mapeocatgasto.idcategoriagastosiges)
        LEFT JOIN (SELECT sum(debito) as importedebito, nroregistro as numeroregistro, anio FROM facturaprestaciones GROUP BY nroregistro, anio) AS fp  USING(numeroregistro,anio)  
	LEFT JOIN  ordenpagocontablereclibrofact  AS opcrlf USING(numeroregistro,anio)  
        LEFT JOIN ordenpagocontable USING (idordenpagocontable,idcentroordenpagocontable) 
	LEFT  JOIN ordenpagocontableestado USING (idordenpagocontable,idcentroordenpagocontable) 
	WHERE nullvalue(opcfechafin) and (idordenpagocontableestadotipo <> 6 OR nullvalue(idordenpagocontableestadotipo)) AND rlf.catgasto = 4 AND rlf.fechaemision >='2020-01-01'
	--AND rlf.fechaemision <=rfiltros.fechahasta
) as t
group by fechaperiodo,tipomovimiento
ORDER BY fechaperiodo
);


update informe_economico set signo = case when tipomovimiento ilike '%egreso%' then -1 else 1 end;

respuesta = 'oki';


return respuesta;
END;
$function$
