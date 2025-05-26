CREATE OR REPLACE FUNCTION public.libroiva_compras_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

-- DROP   TABLE temp_libroiva_compras_contemporal;
CREATE TEMP  TABLE temp_libroiva_compras_contemporal 
AS (

SELECT    pffechadesde fechadesde,pffechahasta fechahasta,
concat(rf.tipofactura,':',letra,' ' ,puntodeventa,'-',numero) as elcomprobante
,concat(puntodeventa,'-',numero) as comprobante
, rf.tipofactura
, letra 
, rf.fechaemision as fechaemision 
, rf.fechaimputacion AS fechaimputacion
, concat(numeroregistro,'-',anio) as numregistro
, p.pcuit AS cuit
, concat(rf.idprestador,' - ',p.pdescripcion) AS razonsocial
, t.descripcioniva AS ivaproveedor  
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * monto as importetotal

------Mod VAS 18/10/22 tk=5443  rlfivadescuento21 // rlfdescuento27 // rlfdescuento105 se descuenta al gravado los descuentos
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * 
                       (case when nullvalue(rf.netoiva21)  then 0 else (  rf.netoiva21 -rlfdescuento21 + rlfrecargo21) end 
                        + case when nullvalue(rf.netoiva105) then 0 else ( rf.netoiva105 - rlfdescuento105 +rlfrecargo105)end 
                        + case when nullvalue(rf.netoiva27)  then 0  else ( rf.netoiva27- rlfdescuento27 + rlfrecargo27) end) 

--16/10/2020 Malapi CASE WHEN p.idcondicioniva = 2 THEN (rf.netoiva21 + rf.netoiva105 + rf.netoiva27 ) ELSE (rf.netoiva21 - rlfivadescuento21 + rf.netoiva105 -rflivadescuento105+ rf.netoiva27-rlfivadescuento27) END 
AS impgravado 

,  (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * ( case when nullvalue(rf.nogravado) then 0 else rf.nogravado end  + case when nullvalue(rf.exento) then 0 else rf.exento end )
--CASE WHEN p.idcondicioniva = 2 THEN (rf.nogravado + rf.exento)ELSE (rf.nogravado + rf.exento) END 
AS impnogravado  
, (-1) * rf.descuento as descuento
, rf.recargo as recargo

--- vas 181022
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(iva21) then 0 else (iva21 -rlfivadescuento21 + rlfivarecargo21) end as impiva21
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(iva105) then 0 else (iva105- rflivadescuento105 + rlfivarecargo105) end as impiva105
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(iva27) then 0 else (iva27 - rlfivadescuento27 + rlfivarecargo27) end  as impiva27
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(netoiva105) then 0 else (netoiva105 - rlfdescuento105 +rlfrecargo105 )  end  as netoiva105	
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(netoiva21 ) then 0 else ( netoiva21 - rlfdescuento21 + rlfrecargo21) end as netoiva21 
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(netoiva27) then 0 else (netoiva27- rlfdescuento27 + rlfrecargo27) end  as netoiva27
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(nogravado) then 0 else nogravado end  as nogravado
, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(retiibb) then 0 else retiibb end  as retiibb

, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) 
           * (case when  rf.idprestador=6297 THEN 1 else 0 end) 
           * retiva as retiva

-- 26-07-19 las percepciones son las que estan cargadas en retenciones de iva
-- , round((case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * (case when nullvalue(rf.percepciones) then 0 else rf.percepciones end ) ::numeric,5) as percepcionesiva 

, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) 
          * (case when  rf.idprestador=6297 THEN 0 else 1 end)
          * (case when nullvalue(rf.retiva) then 0 else rf.retiva end)  as percepcionesiva 

--MaLaPi 19-2-2019 No cambiar la cantidad de caracteres o de decimales del campo "percepcionesiva" se necesita asi para un txt
, 0 as impotrosimpuestos 	
, case when mcg.nrocuentac ilike '107%' then 2 else 1 end tipoGasto
-- 16/10/2020 MaLaPi saco que los centros de costos sean la actividad, ahora uso el campo actividad del registro
--, case when nullvalue(act.nombrecentrocosto) then 'OSocial' else act.nombrecentrocosto end as actividad
--, case when nullvalue(act.id) then '1' else act.id end as idactividad

, case when nullvalue(rf.idactividad) then 'Obra Social' else actividad.acdescripcion end as actividad
, case when nullvalue(rf.idactividad) then '1' else rf.idactividad end as idactividad

,idperiodofiscal
,pcgastodirfarm
,pcgastodirosu
, asientogenerico_daridasientogenerico (concat(rf.numeroregistro,'|',rf.anio)) as nroasientos

-- 16/10/2020 MaLaPi saco que los centros de costos sean la actividad, ahora uso el campo actividad del registro
--,case when (nullvalue(act.id) or act.id=1) 
--           and (not pcgastodirosu or nullvalue(pcgastodirosu) ) 
--           and (not pcgastodirfarm or nullvalue(pcgastodirfarm) )then true
-- else false end as gasto_indirectososunc   -- cuando la actividad es SOSUNC pero no esta clasificado el prestador como gasto directo entonces es INDIRECTO

,case when (nullvalue(rf.idactividad) or rf.idactividad=1) 
           and (not pcgastodirosu or nullvalue(pcgastodirosu) ) 
          and (not pcgastodirfarm or nullvalue(pcgastodirfarm) )then true
 else false end as gasto_indirectososunc   -- cuando la actividad es SOSUNC pero no esta clasificado el prestador como gasto directo entonces es INDIRECTO

-- 16/10/2020 MaLaPi saco que los centros de costos sean la actividad, ahora uso el campo actividad del registro
,case when (rf.idactividad=2) 
            and (not pcgastodirosu or nullvalue(pcgastodirosu) ) 
            and  (not pcgastodirfarm or nullvalue(pcgastodirfarm) ) then true
 else false end as gasto_indirectofarma   -- cuando la actividad es FARMA pero no esta clasificado el prestador como gasto directo entonces es INDIRECTO

--,case when (act.id=2) 
--            and (not pcgastodirosu or nullvalue(pcgastodirosu) ) 
--            and  (not pcgastodirfarm or nullvalue(pcgastodirfarm) ) then true
-- else false end as gasto_indirectofarma   -- cuando la actividad es FARMA pero no esta clasificado el prestador como gasto directo entonces es INDIRECTO
,percepciones as otros_imp   --VAS 15-11-22

,impdebcred as impuesto_debito_credito

,'1-Actividad#actividad@2-Comprobante#elcomprobante@3-Emision#fechaemision@4-Imputacion#fechaimputacion@5-Registro#numregistro@6-Cuit#cuit@7-Razon Social#razonsocial@8-Iva Proveedor#ivaproveedor@9-$_Total#importetotal@10-$_Gravado#impgravado@11-$_No_Gravado#impnogravado@12-Neto_iva21#netoiva21@13-Neto_iva105#netoiva105@14-Neto_iva27#netoiva27@15-$_iva21#impiva21@16-$_iva105#impiva105@17-$_iva27#impiva27@18-IIBB#retiibb@19-Retencion_IVA#retiva@20-Percepciones#percepcionesiva@21-Descuento#descuento@22-Recargo#recargo@23-NRO-Asientos#nroasientos@24-gastodirectososunc#pcgastodirosu@25-gastodirecto_farma#pcgastodirfarm@26-gastoindirecto_farma#gasto_indirectofarma@27-gastoindirecto_sosunc#gasto_indirectososunc@28-otros_imp#otros_imp@29-imp_deb_cred#impuesto_debito_credito'::text as mapeocampocolumna 

FROM  reclibrofact AS rf
JOIN prestador p on (rf.idprestador=p.idprestador)
LEFT JOIN prestadorconfig pc on (p.idprestador = pc.idprestador)
JOIN condicioniva t on (p.idcondicioniva=t.idcondicioniva)
JOIN contabilidad_periodofiscalreclibrofact using (idrecepcion,idcentroregional)
natural join contabilidad_periodofiscal cpf
LEFT JOIN multivac.mapeocatgasto mcg on (rf.catgasto=mcg.idcategoriagastosiges)
-- 16/10/2020 MaLaPi saco que los centros de costos sean la actividad, ahora uso el campo actividad del registro
--LEFT JOIN (
--		SELECT  max(monto) montocentro,replace(text_concatenar(idcentrocosto),' ','') id, text_concatenar(nombrecentrocosto) nombrecentrocosto,idrecepcion,idcentroregional
--        FROM reclibrofactitemscentroscosto
--        NATURAL JOIN centrocosto
--       GROUP BY idrecepcion,idcentroregional
--	) as act USING (idrecepcion,idcentroregional)
LEFT JOIN actividad USING(idactividad)
WHERE  idperiodofiscal = rfiltros.idperiodofiscal
 

);

return true;
END;$function$
