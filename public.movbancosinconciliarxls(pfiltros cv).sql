CREATE OR REPLACE FUNCTION public.movbancosinconciliarxls(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;
        datoconciliacion RECORD;
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   select into datoconciliacion * from conciliacionbancaria where idconciliacionbancaria=rfiltros.idconciliacionbancaria 
             and  idcentroconciliacionbancaria=rfiltros.idcentroconciliacionbancaria ;

   
   /*iria esta consulta*/
CREATE TEMP TABLE temp_movbancosinconciliarxls
   AS (
   SELECT DISTINCT
 idbancamovimiento, bmfecha	,bmnrocomprobante
,bmdebito ,	bmcredito

, CASE WHEN (bmdebito <> 0 ) THEN bmdebito ELSE (-1)*bmcredito END as bmsaldo


,bmconcepto
,conciliacionbancaria_montoconciliado(idbancamovimiento::varchar ,concat('{tipomov=banco}')) as impconc
,'1-FechaReal#bmfecha@2-Concepto#bmconcepto@3-BMDebito#bmdebito@4-BMCredito#bmcredito@5-ImpConc#impconc'::text as mapeocampocolumna

FROM bancamovimiento
left  JOIN bancamovimientocodigo USING (bmcodigo)
LEFT JOIN conciliacionbancariaitem USING (idbancamovimiento)
LEFT JOIN conciliacionbancaria USING (idconciliacionbancaria,idcentroconciliacionbancaria)
LEFT JOIN conciliacionbancariaestado   USING (idconciliacionbancaria,idcentroconciliacionbancaria)
LEFT JOIN conciliacionbancariaestadotipo USING ( idconciliacionbancariaestadotipo)

WHERE  bmfecha >=datoconciliacion.cbfechadesdemovimiento::date
       and bmfecha<=datoconciliacion.cbfechahastamovimiento::date
and bancamovimiento.idcuentabancaria=datoconciliacion.idcuentabancaria 
       and (bmcredito+bmdebito) - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar ,concat('{tipomov=banco}')) >1
ORDER BY idbancamovimiento DESC);
   

return true;
END;
$function$
