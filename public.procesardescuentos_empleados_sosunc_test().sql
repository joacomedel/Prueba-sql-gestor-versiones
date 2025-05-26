CREATE OR REPLACE FUNCTION public.procesardescuentos_empleados_sosunc_test()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD	
	relosdtos RECORD;

--CURSOR
	closdtos REFCURSOR;
BEGIN
     	---- 1 corroboro que no queden descuentos sin procesar por error en carga de afiliaciones
	 	---   Informo los errores en los descuentos realizados
    	INSERT INTO infomeerrordescuentosplanilla (legajosiu,importe,mesingreso,anioingreso,nroliquidacion,nrocargo)
           (  SELECT emlegajo::integer, round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2),limes,lianio,idliquidacion
						            ,CASE WHEN idliquidaciontipo = 1 THEN (99000 + emlegajo ::integer)
						                 WHEN idliquidaciontipo = 2 THEN  (198000 + emlegajo::integer) END
						 
 			   FROM ca.liquidacion 
 			   NATURAL JOIN ca.conceptoempleado 
 			   NATURAL JOIN ca.concepto 
 			   NATURAL JOIN ca.empleado 
 			   NATURAL JOIN ca.persona
 			   LEFT JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu 
				       FROM cargo 
				       WHERE  iddepen='SOS' OR  iddepen='FARM' 
   	    			       GROUP BY nrodoc,tipodoc,legajosiu 
 				) as t  ON(t.tipodoc=idtipodocumento and t.nrodoc=penrodoc) 
            	           WHERE nullvalue(t.nrodoc)  -- hay error en los datos del cargo
                                 AND limes=date_part('month', current_date -30)  
			         AND lianio= date_part('year', current_date -30)  -- identifica la liquidacion
				 AND(idconcepto=387 OR idconcepto=388  OR idconcepto=373 OR idconcepto=360 OR idconcepto=374) -- identifica el concepto
				AND round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) >0.01 -- valor tiene que ser >1
             );


             --- 2 Incorporo los descuentos de los empleados de sosunc 
       CREATE TEMP TABLE descuentososunc (	mesingreso INTEGER,	anioingreso INTEGER,	nroliquidacion INTEGER,	legajosiu INTEGER,	nrocargo INTEGER,	nroconcepto INTEGER,	importe double precision,	tipodoc INTEGER,	nrodoc VARCHAR	) WITHOUT OIDS;
	   OPEN closdtos FOR  SELECT limes, lianio , idliquidacion, t.legajosiu, t.idcargo,
		 		idconcepto,  round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) as importe
 				,idtipodocumento,penrodoc
 					FROM ca.liquidacion 
 					NATURAL JOIN ca.conceptoempleado 
 					NATURAL JOIN ca.concepto 
 					NATURAL JOIN ca.empleado 
 					NATURAL JOIN ca.persona
 					JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu 
							FROM cargo 
							WHERE  iddepen='SOS' OR  iddepen='FARM' 
   	    					GROUP BY nrodoc,tipodoc,legajosiu /* order by nrodoc */
 					) as t  ON(t.tipodoc=idtipodocumento and t.nrodoc=penrodoc) 
					LEFT JOIN informedescuentoplanillav2 AS idp ON (
              					idliquidacion=idp.nroliquidacion 
               					AND t.legajosiu=idp.legajosiu 
               					AND idconcepto=idp.concepto 
               					AND t.idcargo=idp.idcargo 
               					AND round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2)=idp.importe  
               					AND limes = mes 
	           					AND lianio = anio
  					)
 					WHERE nullvalue(idp.idinforme)  -- No se encuentra registro de descuento 
        			AND limes=date_part('month', current_date -30)  AND lianio= date_part('year', current_date -30)  -- identifica la liquidacion
						AND(idconcepto=387 OR idconcepto=388  OR idconcepto=373 OR idconcepto=360 OR idconcepto=374) -- identifica el concepto
						AND round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) >0.01 -- valor tiene que ser >1
						;
		FETCH closdtos INTO relosdtos;
		WHILE  FOUND LOOP

    		INSERT INTO descuentososunc(mesingreso,	anioingreso,nroliquidacion,legajosiu,nrocargo,nroconcepto,importe,tipodoc,nrodoc)
			VALUES (relosdtos.limes, relosdtos.lianio,relosdtos.idliquidacion,relosdtos.legajosiu,relosdtos.idcargo,relosdtos.idconcepto,relosdtos.importe,relosdtos.idtipodocumento,relosdtos.penrodoc);

    		FETCH closdtos INTO relosdtos;
		END LOOP;
		CLOSE closdtos;
	

--llamo al sp que ingresa los datos de los descuentos de los empleados de SOSUNC
--esto lo vi comentado el 08102022 y no se recuerda porq esta asi. Lo dejo descomentado
--PERFORM agregardescuentosconceptossosunc();
PERFORM agregardescuentosconceptossosunc_test();

/*Dani agrego el 24-11-2021 para ver que aca procese lso descuentos de empleados de la farmacia*/
/*revisar que el sp procesardescuentos_empleados_farmacia se uso para el caso de Daniela Torres, legajo=20, dni 32037023*/

--llamo al sp que ingresa los datos de los descuentos de los empleados de la farmacia 
--MaLaPi 20-07-2022 Lo comento porque este SP en la Linea 84 solo verifica si existe el movimiento en la cta.cte teniendo en cuenta el IMPORTE y eso esta MAL
--RAISE EXCEPTION 'Ver comentarios de Error: ';
-- PERFORM agregardescuentosconceptossosuncempfarmacia('farmacia');
 

return 'true';
END;
$function$
