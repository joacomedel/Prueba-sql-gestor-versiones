CREATE OR REPLACE FUNCTION public.far_traercoberturasarticuloafiliado_validador(character varying, bigint, bigint, bigint, integer, character varying)
 RETURNS SETOF far_plancoberturamedicamentoafiliado
 LANGUAGE sql
AS $function$-- Cobertura del medicamento para el Afiliado y la OSocial del Recetario

-- GK 2023-01-10 
-- Agrego conttrol de importe max de cobertura sin auditoria 

--Busca la cobertura en sosunc
SELECT  o.idobrasocial::bigint,
	ov.idvalorescaja::bigint,	
	0 as idafiliado,
	 m.mnroregistro::text,
	 3 as prioridad,
	--CASE WHEN nullvalue(saicobertura) THEN multiplicador ELSE saicobertura END as porcCob,
	CASE WHEN nullvalue(fmimcobertura) THEN multiplicador 
	ELSE 
			CASE WHEN fmimcobertura > 1 THEN fmimcobertura/100
			ELSE 
				fmimcobertura
			END  
	END as porcCob,
	--multiplicadoras porcCob,
	vmimporte::double precision as montoFijo,    	
	o.osdescripcion as pdescripcion,	
	concat(ov.idvalorescaja::text , '-' , o.osdescripcion) as detalle,
	--- VAS 290424 '0' as codautorizacion
CASE WHEN nullvalue(cobesp.idfichamedicainfomedicamento) THEN  '0'
ELSE concat(cobesp.idfichamedicainfomedicamento::character varying ,cobesp.idcentrofichamedicainfomedicamento::character varying) END as codautorizacion
 
/*VASYPRA	020524
FROM medicamento AS m
LEFT JOIN valormedicamento using (mnroregistro)
LEFT JOIN  manextra using (mnroregistro)
NATURAL JOIN plancoberturafarmacia
LEFT JOIN solicitudauditoriaitem sai ON (idsolicitudauditoria=$6 AND sai.idmonodroga=manextra.idmonodroga)
LEFT JOIN fichamedicainfomedicamento as fmim USING(idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento)
CROSS JOIN (select * from far_obrasocial WHERE idobrasocial = 1 ) as o
--NATURAL JOIN far_afiliado
NATURAL JOIN far_obrasocialvalorescaja AS ov --USING(idobrasocial)
LEFT JOIN far_validacion AS fv ON(fincodigo =1 AND idvalidacion = $5)	
WHERE  
	--idobrasocial = 1 
	--and 
	mnroregistro = $1 
	and nullvalue(fechafinvigencia)
	AND nullvalue( 	vmfechafin )
	--AND idafiliado = $3  
	AND (NULLVALUE(fv.fincodigo) or  fv.fincodigo <> idobrasocial)
	AND idfarmtipoventa <> 1 --MALAPI 04-11-2013 SOSUNC y AMUC no cubren los medicamentos de venta libre
GROUP BY idobrasocial,idvalorescaja,idafiliado,mnroregistro,prioridad,porccob,montofijo,pdescripcion,detalle,codautorizacion
*/

FROM  medicamento AS m
LEFT JOIN valormedicamento using (mnroregistro)
LEFT JOIN  manextra using (mnroregistro)
NATURAL JOIN plancoberturafarmacia
LEFT JOIN ( SELECT fmim.idmonodroga ,
                   MAX(fmim.idfichamedicainfomedicamento) as idfichamedicainfomedicamento,
                   MIN(fmim.idcentrofichamedicainfomedicamento) as idcentrofichamedicainfomedicamento

	    FROM solicitudauditoria sa
            JOIN solicitudauditoriaitem sai USING (idsolicitudauditoria,idcentrosolicitudauditoria)
	    JOIN fichamedicainfomedicamento as fmim USING(idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento)
            LEFT JOIN solicitudauditoriaitem_ext as saie USING(idsolicitudauditoriaitem,idcentrosolicitudauditoriaitem	) 
		    WHERE ---  nrodoc =  $3 
		   
		   nrodoc =  CASE WHEN length($3)=7 THEN concat('0',$3::character varying) ELSE $3::character varying END 
		   --- '31671819'  --- nrodoc =  '27091730'  --- nrodoc =  '27349352' 
		          AND (nullvalue(fmimfechafin) OR 	fmimfechafin>=now() ) --- es una linea de auditoria vigente 
		          AND (  (not nullvalue($6 ) AND sa.idsolicitudauditoria=$6  ) -- tengo dictamen
				 OR (nullvalue($6 ) AND  not nullvalue(saie.idsolicitudauditoriaitem) ) -- tengo cobertura especial
			  )  
		   GROUP BY fmim.idmonodroga
) as cobesp USING(idmonodroga )
LEFT JOIN fichamedicainfomedicamento as  fmim USING(idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento,idmonodroga)   
CROSS JOIN (select * from far_obrasocial WHERE idobrasocial = 1 ) as o
--NATURAL JOIN far_afiliado
NATURAL JOIN far_obrasocialvalorescaja AS ov --USING(idobrasocial)
LEFT JOIN far_validacion AS fv ON(fincodigo =1 AND idvalidacion = $5)	
WHERE     mnroregistro = $1 --- info del medicamento
	AND nullvalue(fechafinvigencia)
	AND nullvalue( 	vmfechafin )
	AND (NULLVALUE(fv.fincodigo) or  fv.fincodigo <> idobrasocial)
-- OJOO 150824	AND idfarmtipoventa <> 1 --MALAPI 04-11-2013 SOSUNC y AMUC no cubren los medicamentos de venta libre
        AND ( 
               (idfarmtipoventa <> 1)  -- No es de venta libre
               OR (not nullvalue(cobesp.idfichamedicainfomedicamento)) -- tengo dictamen 
             ) -- tengo dictamen 

GROUP BY idobrasocial,idvalorescaja,idafiliado,mnroregistro,prioridad,porccob,montofijo,pdescripcion,detalle,codautorizacion

$function$
