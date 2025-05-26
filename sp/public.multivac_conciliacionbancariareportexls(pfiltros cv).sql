CREATE OR REPLACE FUNCTION public.multivac_conciliacionbancariareportexls(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
   CREATE TEMP TABLE temp_movconciliadosxls
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
  
return true;
END;
$function$
