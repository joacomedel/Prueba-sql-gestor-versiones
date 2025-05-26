CREATE OR REPLACE FUNCTION public.informe_descuento_planilla_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rfiltros record;
        
	
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_informe_descuento_planilla_contemporal
	AS (
		SELECT concat(apellido, '  ' ,nombres) as afiliado, concat(nrodoc, '-',barra) as nroafiliado, barra, datospersona.legajosiu as nrolegajo, E.idconcepto,importeenviado,        
                        CASE WHEN nullvalue(importerecibido) THEN 0 ELSE importerecibido end as importerecibido ,                                       
                        CASE WHEN (barra =32 or barra=35 or barra=36) THEN 'LIQ SOSUNC' ELSE 'LIQ UNC' end as eltipoliq, 
                        case when E.cancelado then 'No se envio' 
                        when not E.cancelado then 'Se envio' END as se_envio
                ,'1-Barra#barra@2-Nro. Afiliado#nroafiliado@3-Tipo Liq.#eltipoliq@4-Afiliado#afiliado@5-ID. Concepto#idconcepto@6-Importe Enviado#importeenviado@7-Importe Recibido#importerecibido@8-Se Envio#se_envio@9-Nro. Legajo#nrolegajo'::text as mapeocampocolumna
                
                FROM    (
                        SELECT  enviodescontarctactev2.tipodoc, enviodescontarctactev2.nrodoc,SUM(enviodescontarctactev2.importe) as importeenviado,enviodescontarctactev2.idconcepto, cancelado 
                        FROM enviodescontarctactev2
                        JOIN cuentacorrientedeuda ON (idmovimiento=iddeuda and idcentromovimiento=idcentrodeuda)
                        WHERE date_part('month',  enviodescontarctactev2.fechaenvio) =  rfiltros.numeromes
                        and date_part('year',  enviodescontarctactev2.fechaenvio) =   rfiltros.numeroanio 
                        GROUP BY enviodescontarctactev2.tipodoc,enviodescontarctactev2.nrodoc,enviodescontarctactev2.idconcepto, cancelado 
                        ) as E
                LEFT JOIN (SELECT nrodoc,tipodoc,legajosiu from afilidoc 
                        union 
                        SELECT nrodoc,tipodoc,legajosiu from afilinodoc 
                        union 
                        SELECT nrodoc,tipodoc,legajosiu From afilisos 
                        union 
                        SELECT nrodoc,tipodoc,legajosiu from afilirecurprop 
                        union  
                        SELECT nrodoc,tipodoc, legajosiu from afiliauto 
                        union 
                        SELECT nrodoc,tipodoc, legajosiu from afiliauto 
                        ) as datospersona USING(nrodoc,tipodoc) 
                LEFT JOIN (
                        SELECT tipodoc, nrodoc,informedescuentoplanillav2.importe as importerecibido,case when concepto= 372 then 360 else concepto end as idconcepto                                    
                        FROM informedescuentoplanillav2
                        WHERE mes =   rfiltros.numeromes
                        and anio =   rfiltros.numeroanio
                        ) as R using (tipodoc, nrodoc,idconcepto)
                NATURAL JOIN persona
                WHERE ( (1 = rfiltros.idpagoparcial or nullvalue(rfiltros.idpagoparcial) )or  round( importeenviado) - round( case when nullvalue( importerecibido) THEN 0 ELSE importerecibido END  )<>0)
                        and  (  case when nullvalue(rfiltros.nrodoc) THEN TRUE else nrodoc=  rfiltros.nrodoc  END )
                ORDER BY eltipoliq 
	);
  

return true;
END;
$function$
