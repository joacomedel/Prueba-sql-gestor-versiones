CREATE OR REPLACE FUNCTION public.far_traercoberturasarticuloafiliado_validador_(character varying, bigint, bigint, bigint, integer, character varying, date)
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
	CASE WHEN (fmimcobertura is null) THEN multiplicador 
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
CASE WHEN cobesp.idfichamedicainfomedicamento is null THEN  '0'
ELSE concat(cobesp.idfichamedicainfomedicamento::character varying ,cobesp.idcentrofichamedicainfomedicamento::character varying) END as codautorizacion
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
	    WHERE nrodoc =  CASE WHEN length($3)=7 THEN concat('0',$3::character varying) ELSE $3::character varying END 
		           -- VAS 040724   AND (nullvalue(fmimfechafin) OR 	fmimfechafin>=now() ) --- es una linea de auditoria vigente 
		            AND (safechaingreso <=$7 AND ($7<=fmimfechafin OR (fmimfechafin is null))) -- VAS 040724  para que busque la cobertura en la fecha enviada por parametro
	   		      ----safechaingreso: al no contar con una fecha de inicio de vigencia del item tome la de creacion de la solicitud de auditoria....
		        
		          AND (  (not ($6 is null) AND sa.idsolicitudauditoria=$6  ) -- tengo dictamen
				          OR (($6 is null) AND  not saie.idsolicitudauditoriaitem is null ) -- tengo cobertura especial
			)  
		   GROUP BY fmim.idmonodroga
) as cobesp USING(idmonodroga )
LEFT JOIN fichamedicainfomedicamento as  fmim USING(idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento,idmonodroga)   
CROSS JOIN (select * from far_obrasocial WHERE idobrasocial = 1 ) as o
NATURAL JOIN far_obrasocialvalorescaja AS ov --USING(idobrasocial)
LEFT JOIN far_validacion AS fv ON(fincodigo =1 AND idvalidacion = $5)	
WHERE  mnroregistro = $1 --- info del medicamento
	   -- VAS 040724 AND nullvalue(fechafinvigencia)
       AND (fechainivigencia <=$7 AND ($7<=fechafinvigencia OR (fechafinvigencia is null))) -- VAS 040724  para que busque la cobertura en la fecha enviada por parametro
	   		
	   
       AND vmfechafin is null
	   
       AND (fv.fincodigo is null or  fv.fincodigo <> idobrasocial)
    ---VAS 080724 lo comento para que puedan auditorar recetarios con medicamentos que pasaron a venta libre    AND idfarmtipoventa <> 1 --MALAPI 04-11-2013 SOSUNC y AMUC no cubren los medicamentos de venta libre
GROUP BY idobrasocial,idvalorescaja,idafiliado,mnroregistro,prioridad,porccob,montofijo,pdescripcion,detalle,codautorizacion

$function$
