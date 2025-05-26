CREATE OR REPLACE FUNCTION public.conciliacionbancaria_movbancosinconciliardesdehastaxls(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;
        datoconciliacion RECORD;
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   SELECT into datoconciliacion * 
   FROM conciliacionbancaria 
   WHERE true
        AND cbfechadesdemovimiento >= rfiltros.fechadesde 
        AND cbfechahastamovimiento <=rfiltros.fechahasta
        AND idcuentabancaria =rfiltros.idcuentabancaria;

   
   /*iria esta consulta*/
CREATE TEMP TABLE temp_conciliacionbancaria_movbancosinconciliardesdehastaxls
   AS (
   SELECT DISTINCT
 idbancamovimiento, bmfecha  ,bmnrocomprobante
,bmdebito , bmcredito

, CASE WHEN (bmdebito <> 0 ) THEN bmdebito ELSE (-1)*bmcredito END as bmsaldo

,bmconcepto
,conciliacionbancaria_montoconciliado(idbancamovimiento::varchar ,concat('{tipomov=banco}')) as impconc
,'1-IDconciliacion#idconciliacionbancaria@2-Centro#idcentroconciliacionbancaria@3-FechaReal#bmfecha@4-Concepto#bmconcepto@5-BMDebito#bmdebito@6-BMCredito#bmcredito@7-ImpConc#impconc'::text as mapeocampocolumna

FROM bancamovimiento
left  JOIN bancamovimientocodigo USING (bmcodigo)
LEFT JOIN conciliacionbancariaitem USING (idbancamovimiento)
LEFT JOIN conciliacionbancaria USING (idconciliacionbancaria,idcentroconciliacionbancaria)
LEFT JOIN conciliacionbancariaestado   USING (idconciliacionbancaria,idcentroconciliacionbancaria)
LEFT JOIN conciliacionbancariaestadotipo USING ( idconciliacionbancariaestadotipo)

WHERE  true
    AND bmfecha >=rfiltros.fechadesde 
    AND bmfecha<=rfiltros.fechahasta
    AND bancamovimiento.idcuentabancaria=rfiltros.idcuentabancaria
    AND (bmcredito+bmdebito) - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar ,concat('{tipomov=banco}')) >1
ORDER BY idbancamovimiento DESC);
   /*
   
   CREATE TEMP TABLE temp_movbancosinconciliarxls
   AS (
       SELECT 
	   
       cbifechaingreso::date ,replace( replace(cbicomsiges, '<', ''),'>','')  as cbicomsiges ,
	   concat(idconciliacionbancariaitem,'0',idcentroconciliacionbancariaitem)as  idconciliacionbancariaitem,
	   cbiimporte,concat(apellido,', ',nombre) as elusuario,bmnrocomprobante,bmfecha,
	   conciliacionbancaria.cbsaldoinicialcb
     , CASE WHEN (bmdebito <> 0 ) THEN cbiimporte ELSE bmdebito END as bmdebito
     , CASE WHEN (bmcredito <> 0 ) THEN cbiimporte ELSE bmcredito END as bmcredito
     ,abs(conciliacionbancariamontofinal(rfiltros.idconciliacionbancaria,rfiltros.idcentroconciliacionbancaria) ) 
	   as saldoconciliacion
,'1-cbifechaingreso#cbifechaingreso@2-cbicomsiges#cbicomsiges@3-idconciliacionbancariaitem#idconciliacionbancariaitem@4-cbiimporte#cbiimporte@5-elusuario#elusuario@6-bmnrocomprobante#bmnrocomprobante@7-bmfecha#bmfecha@8-cbsaldoinicialcb#cbsaldoinicialcb@9-bmdebito#bmdebito@9-bmcredito#bmcredito@10-saldoconciliacion#saldoconciliacion'::text as mapeocampocolumna

       
     

FROM conciliacionbancaria
NATURAL JOIN conciliacionbancariaitem
JOIN bancamovimiento USING (idbancamovimiento)
left JOIN bancamovimientocodigo using (bmcodigo)
  JOIN conciliacionbancariaestado  using(idconciliacionbancaria,idcentroconciliacionbancaria)
NATURAL JOIN conciliacionbancariaestadotipo
  JOIN usuario on(usuario.idusuario=conciliacionbancariaitem.idusuario)
WHERE   idconciliacionbancaria = rfiltros.idconciliacionbancaria 
             and  idcentroconciliacionbancaria =rfiltros.idcentroconciliacionbancaria
            AND cbiactivo and nullvalue(conciliacionbancariaestado.cbcefechafin)
order by idbancamovimiento desc );
  */
return true;
END;
$function$
