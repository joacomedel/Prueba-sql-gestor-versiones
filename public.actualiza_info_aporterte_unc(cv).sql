CREATE OR REPLACE FUNCTION public.actualiza_info_aporterte_unc(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	rfiltros record; 
        

BEGIN
 /*select  * from actualiza_info_aporterte_unc('{mes=date_part('month', current_date -30),anio=date_part('year', current_date -30)}');*/
 EXECUTE sys_dar_filtros($1) INTO rfiltros;

 
 INSERT INTO info_aporterte_unc (nrodoctitu,tipodoctitu,apeynom,imp_bruto,imp_aporte,imp_contribucion,imp_conyuge,idcateg,mes,anio,nroliquidacion,idcargo )
(
    SELECT nrodoctitu,	tipodoctitu,apeynom ,imp_bruto,imp_aporte,imp_contribucion,imp_conyuge  ,idcateg, rfiltros.mes as mes,rfiltros.anio as anio,nroliquidacion,idcargo 
    FROM (
      SELECT nrodoc as nrodoctitu,tipodoc as tipodoctitu  ,concat(apellido,' ', nombres) as apeynom ,  idcargo   , imp_bruto ,imp_aporte,imp_contribucion ,imp_conyuge, idcateg,nroliquidacion
      FROM (
            SELECT  idcargo   ,  '311-aporte'as concepto ,concepto.importe as imp_aporte,nroliquidacion
            FROM aporte
            JOIN concepto USING(mes,ano,idlaboral,nroliquidacion)
            WHERE idconcepto = 311 -- aporte 
                  AND mes = rfiltros.mes AND ano=rfiltros.anio 
      ) as TA 
      JOIN( SELECT idcargo    ,  '-51-Bruto' as concepto ,concepto.importe as imp_bruto,nroliquidacion
            FROM aporte
            JOIN concepto USING(mes,ano,idlaboral,nroliquidacion)
            WHERE idconcepto = -51 -- bruto
                  AND mes = rfiltros.mes AND ano=rfiltros.anio 
      )as TB USING(idcargo,nroliquidacion) 
      JOIN(
            SELECT idcargo   ,  '-51-contribucion'as concepto ,concepto.importe as imp_contribucion,nroliquidacion
            FROM aporte
            JOIN concepto USING(mes,ano,idlaboral,nroliquidacion)
            WHERE idconcepto = 911-- contribucion
                  AND mes = rfiltros.mes AND ano=rfiltros.anio 
      )as TC  USING(idcargo,nroliquidacion)
      LEFT JOIN(
            SELECT  idcargo   ,  '392-aporte conyuge' as concepto ,concepto.importe as imp_conyuge,nroliquidacion
            FROM aporte
            JOIN concepto USING(mes,ano,idlaboral,nroliquidacion)
            WHERE idconcepto = 392 -- conyuge 
                  AND mes = rfiltros.mes AND ano=rfiltros.anio 

      )as TCON  USING(idcargo,nroliquidacion)
      JOIN cargo USING (idcargo)
      JOIN persona USING(nrodoc,tipodoc)
      WHERE true --- AND nrodoc='27091730'
           --  AND nroliquidacion = 581
      GROUP BY (nrodoctitu,	tipodoctitu,	apeynom	,idcargo,	imp_bruto,	imp_aporte,	imp_contribucion,imp_conyuge,nroliquidacion)
   ) as T
);

return true;
END;$function$
