CREATE OR REPLACE FUNCTION public.conciliacionbancaria_movconciliadosdesdehastaxls(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
    
       CREATE TEMP TABLE temp_conciliacionbancaria_movconciliadosdesdehastaxls
   AS (
       SELECT 
       idconciliacionbancaria,
       idcentroconciliacionbancaria,
	    cbifechaingreso::date ,replace( replace(cbicomsiges, '<', ''),'>','')  as cbicomsiges ,
	   concat(idconciliacionbancariaitem,'0',idcentroconciliacionbancariaitem)as  idconciliacionbancariaitem,
       cbiimporte,bmnrocomprobante,bmfecha
     , CASE WHEN (bmdebito <> 0 ) THEN cbiimporte ELSE bmdebito END as bmdebito
     , CASE WHEN (bmcredito <> 0 ) THEN cbiimporte ELSE bmcredito END as bmcredito
     
,'1-IDconciliacion#idconciliacionbancaria@2-Centro#idcentroconciliacionbancaria@3-FConciliacion#cbifechaingreso@4-Comprobante#cbicomsiges@5-IDIC#idconciliacionbancariaitem@6-MontoConc#cbiimporte@7-BMComp#bmnrocomprobante@8-FechaReal#bmfecha@9-BMDebito#bmdebito@10-BMCredito#bmcredito'::text as mapeocampocolumna

       
     
       
     

FROM conciliacionbancaria
NATURAL JOIN conciliacionbancariaitem
JOIN bancamovimiento USING (idbancamovimiento)
left JOIN bancamovimientocodigo using (bmcodigo)
JOIN conciliacionbancariaestado  using(idconciliacionbancaria,idcentroconciliacionbancaria)
NATURAL JOIN conciliacionbancariaestadotipo
JOIN usuario on(usuario.idusuario=conciliacionbancariaitem.idusuario)
WHERE   true
AND cbfechadesdemovimiento >= rfiltros.fechadesde 
AND cbfechahastamovimiento <=rfiltros.fechahasta
AND conciliacionbancaria.idcuentabancaria =rfiltros.idcuentabancaria  
AND cbiactivo 
AND nullvalue(conciliacionbancariaestado.cbcefechafin)
ORDER BY idbancamovimiento desc );
  
return true;
END;
$function$
