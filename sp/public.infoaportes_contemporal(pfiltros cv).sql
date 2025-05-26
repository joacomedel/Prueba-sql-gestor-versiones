CREATE OR REPLACE FUNCTION public.infoaportes_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE      	
	rfiltros record;
	
BEGIN 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_infoaportes_contemporal
AS (
	SELECT nrodoctitu,	tipodoctitu,apeynom ,imp_bruto,imp_aporte,imp_contribucion,imp_conyuge  ,idcateg,rfiltros.mes,rfiltros.anio,iaufechaingreso,nroliquidacion,idcargo
 
,'1-Nro.Documento#nrodoctitu@2-Apellido y Nombres#apeynom@3-Importe Bruto#imp_bruto@4-Importe Aporte#imp_aporte@5-Importe Contribucion#imp_contribucion@6-Importe Conyuge#imp_conyuge@7-Categoria#idcateg@8-Mes#mes@9-Anio#anio@10-Fecha Ingreso#iaufechaingreso@11-Nro Liquidacion#nroliquidacion@12-Cargo#idcargo'::text as mapeocampocolumna


FROM info_aporterte_unc

where  mes = rfiltros.mes AND anio=rfiltros.anio 
/*(
      SELECT nrodoc as nrodoctitu,tipodoc as tipodoctitu  ,concat(apellido,' ', nombres) as apeynom ,  idcargo   , imp_bruto ,imp_aporte,imp_contribucion ,imp_conyuge, idcateg,rfiltros.mes,rfiltros.anio
      FROM (
            SELECT idcargo   ,  '311-aporte'as concepto ,concepto.importe as imp_aporte
            FROM aporte
            JOIN concepto USING(mes,ano,idlaboral)
            WHERE idconcepto = 311 -- aporte 
                  AND mes = rfiltros.mes AND ano=rfiltros.anio 
      ) as TA 
      JOIN( SELECT idcargo    ,  '-51-Bruto' as concepto ,concepto.importe as imp_bruto
            FROM aporte
            JOIN concepto USING(mes,ano,idlaboral)
            WHERE idconcepto = -51 -- bruto
                  AND mes = rfiltros.mes AND ano=rfiltros.anio 
      )as TB USING(idcargo) 
      JOIN(
            SELECT idcargo   ,  '-51-contribucion'as concepto ,concepto.importe as imp_contribucion
            FROM aporte
            JOIN concepto USING(mes,ano,idlaboral)
            WHERE idconcepto = 911-- contribucion
                  AND mes = rfiltros.mes AND ano=rfiltros.anio 
      )as TC  USING(idcargo)
      LEFT JOIN(
            SELECT idcargo   ,  '392-aporte conyuge' as concepto ,concepto.importe as imp_conyuge
            FROM aporte
            JOIN concepto USING(mes,ano,idlaboral)
            WHERE idconcepto = 392 -- conyuge 
                  AND mes = rfiltros.mes AND ano= rfiltros.anio 

      )as TCON  USING(idcargo)
      JOIN cargo USING (idcargo)
      JOIN persona USING(nrodoc,tipodoc)
      WHERE true --- AND nrodoc='27091730'
      GROUP BY (nrodoctitu,	tipodoctitu,	apeynom	,idcargo,	imp_bruto,	imp_aporte,	imp_contribucion,imp_conyuge)
   ) as T*/

);
     

return true;
END;
$function$
