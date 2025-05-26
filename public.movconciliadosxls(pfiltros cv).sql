CREATE OR REPLACE FUNCTION public.movconciliadosxls(pfiltros character varying)
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
       cbiimporte,bmnrocomprobante,bmfecha
     , CASE WHEN (bmdebito <> 0 ) THEN cbiimporte ELSE bmdebito END as bmdebito
     , CASE WHEN (bmcredito <> 0 ) THEN cbiimporte ELSE bmcredito END as bmcredito,
     concat(idasientogenerico,'|', idcentroasientogenerico) as elasiento, agfechacontable
     
,'1-FConciliacion#cbifechaingreso@2-Comprobante#cbicomsiges@3-IDIC#idconciliacionbancariaitem@4-MontoConc#cbiimporte@5-BMComp#bmnrocomprobante@6-FechaReal#bmfecha@7-BMDebito#bmdebito@8-BMCredito#bmcredito@9-Asiento#elasiento@10-Fecha_Contable#agfechacontable'::text as mapeocampocolumna


       
     
       
     

FROM conciliacionbancaria
NATURAL JOIN conciliacionbancariaitem
LEFT JOIN asientogenerico USING (idasientogenerico, idcentroasientogenerico)
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
