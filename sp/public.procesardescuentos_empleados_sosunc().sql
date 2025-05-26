CREATE OR REPLACE FUNCTION public.procesardescuentos_empleados_sosunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* 
	Dado un mes y año se procesan los descuentos de los empleados de sosunc.
*/
DECLARE
--RECORD	
	relosdtos RECORD;

--CURSOR
	closdtos REFCURSOR;
BEGIN

CREATE TEMP TABLE descuentososunc (	mesingreso INTEGER,	anioingreso INTEGER,	nroliquidacion INTEGER,	legajosiu INTEGER,	nrocargo INTEGER,	nroconcepto INTEGER,	importe double precision,	tipodoc INTEGER,	nrodoc VARCHAR	) WITHOUT OIDS;
OPEN closdtos FOR 
        SELECT penrodoc,idtipodocumento,idconcepto,  round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) as importe, 
		 t.idcargo,t.legajosiu, idliquidacion,limes,lianio,tdnombre,codescripcion 
		 FROM ca.liquidacion 
		 NATURAL JOIN ca.liquidacionempleado 
		 NATURAL JOIN ca.conceptoempleado 
		 NATURAL JOIN ca.concepto 
		 NATURAL JOIN ca.empleado 
		 NATURAL JOIN ca.persona 	
		 JOIN (SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu 
		       FROM cargo 
		       WHERE  iddepen='SOS' 
/*Dani agrego la union el 20220418 para incluir al personal de farmacia*/
		       GROUP BY nrodoc,tipodoc,legajosiu /* order by nrodoc */
         	   UNION
--KT 20-07-22 corrigo pq desde julio 2022 lozano es empleada de sosunc pero tiene cta cte como adherente, se le desconto en los haberes de junio y no se proceso pq en julio ya no era empleada de farmacia, y tiene los 3 meses de carencia
        	   SELECT penrodoc nrodoc,idtipodocumento tipodoc, 0 as idcargo, emlegajo::bigint  as legajosiu 
		 	   FROM ca.persona 
	     	   NATURAL JOIN ca.empleado 
	     	   NATURAL JOIN ca.categoriaempleado 
	     	   NATURAL JOIN ca.grupoliquidacionempleado
         	   LEFT JOIN persona p ON (penrodoc =nrodoc and 	idtipodocumento= tipodoc)
		 	   WHERE   idcategoriatipo=1
			     	   and (idgrupoliquidaciontipo=2   or p.barra=35 )
                 	   and   (nullvalue(cefechafin) or cefechafin >=to_timestamp(concat(extract (year from current_date),'-',extract (month from current_date),'-1') ,'YYYY-MM-DD')::date)
		  ) as t  ON(t.tipodoc=idtipodocumento and t.nrodoc=penrodoc) 
		 NATURAL JOIN ca.tipodocumento 
         LEFT JOIN informedescuentoplanillav2 AS idp ON (
			                                            idliquidacion=idp.nroliquidacion 
			                                            AND t.legajosiu=idp.legajosiu 
			                                            AND idconcepto=idp.concepto 
			                                            AND  t.idcargo=idp.idcargo 
			                                            AND  round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2)=idp.importe  
			                                            AND date_part('month', current_date -30) =mes 
			                                            AND  date_part('year', current_date -30)=anio
		  )
	   	 WHERE limes=date_part('month', current_date -30) 
		        AND lianio= date_part('year', current_date -30) 
		        AND nullvalue(idp.idinforme) and round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) >0.01
		        AND(idconcepto=387 OR idconcepto=388  OR idconcepto=373 OR idconcepto=360 OR idconcepto=374);
   	
FETCH closdtos INTO relosdtos;
WHILE  FOUND LOOP
	INSERT INTO descuentososunc(mesingreso,	anioingreso,nroliquidacion,legajosiu,nrocargo,nroconcepto,importe,tipodoc,nrodoc)
	VALUES (relosdtos.limes, relosdtos.lianio,
relosdtos.idliquidacion,relosdtos.legajosiu,relosdtos.idcargo,relosdtos.idconcepto,relosdtos.importe,relosdtos.idtipodocumento,relosdtos.penrodoc);

--	VALUES (12,2018,relosdtos.idliquidacion,relosdtos.legajosiu,relosdtos.idcargo,relosdtos.idconcepto,relosdtos.importe,relosdtos.idtipodocumento,relosdtos.penrodoc);

FETCH closdtos INTO relosdtos;
END LOOP;
CLOSE closdtos;
	

--llamo al sp que ingresa los datos de los descuentos de los empleados de SOSUNC
--esto lo vi comentado el 08102022 y no se recuerda porq esta asi. Lo dejo descomentado
PERFORM agregardescuentosconceptossosunc();

/*Dani agrego el 24-11-2021 para ver que aca procese lso descuentos de empleados de la farmacia*/
/*revisar que el sp procesardescuentos_empleados_farmacia se uso para el caso de Daniela Torres, legajo=20, dni 32037023*/

--llamo al sp que ingresa los datos de los descuentos de los empleados de la farmacia 
--MaLaPi 20-07-2022 Lo comento porque este SP en la Linea 84 solo verifica si existe el movimiento en la cta.cte teniendo en cuenta el IMPORTE y eso esta MAL
--RAISE EXCEPTION 'Ver comentarios de Error: ';
-- PERFORM agregardescuentosconceptossosuncempfarmacia('farmacia');
 

return 'true';
END;
$function$
