CREATE OR REPLACE FUNCTION public.procesardescuentos_empleados_farmacia(character varying)
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
--para solucionar el tk 4545 setear con 90 dias y legajo=20
CREATE TEMP TABLE descuentososunc (	mesingreso INTEGER,	anioingreso INTEGER,	nroliquidacion INTEGER,	legajosiu INTEGER,	nrocargo INTEGER,	nroconcepto INTEGER,	importe double precision,	tipodoc INTEGER,	nrodoc VARCHAR	) WITHOUT OIDS;
OPEN closdtos FOR  SELECT penrodoc,idtipodocumento,idconcepto,  round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) as importe, 
		ca.empleado.emlegajo::INTEGER as idcargo,ca.empleado.emlegajo::INTEGER as legajosiu, idliquidacion,limes,lianio,tdnombre,codescripcion,idliquidacion 
		 FROM ca.liquidacion NATURAL JOIN ca.liquidacionempleado 
		 NATURAL JOIN ca.conceptoempleado NATURAL JOIN ca.concepto 
		 NATURAL JOIN ca.empleado NATURAL JOIN ca.persona 	
		 NATURAL JOIN ca.tipodocumento 
                 LEFT JOIN informedescuentoplanillav2 AS idp ON (idliquidacion=idp.nroliquidacion AND ca.empleado.emlegajo=idp.legajosiu 
                      AND idconcepto=idp.concepto /*AND  t.idcargo=idp.idcargo */AND 
                       round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2)=idp.importe  
			--AND date_part('month', current_date -30) =mes AND  date_part('year', current_date -30)=anio)
AND date_part('month', current_date -90) =mes AND  date_part('year', current_date -90)=anio)
	 
        	 WHERE 
--limes=date_part('month', current_date -30) and lianio= date_part('year', current_date -30) AND 
limes=date_part('month', current_date -90) and lianio= date_part('year', current_date -90) AND  ca.empleado.emlegajo=20 and 

	 ca.liquidacion.idliquidaciontipo=2 and 
nullvalue(idp.idinforme) and round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) >0.01
		 AND(idconcepto=387 OR idconcepto=373 OR idconcepto=360 OR idconcepto=374);
   	
FETCH closdtos INTO relosdtos;
WHILE  FOUND LOOP
	INSERT INTO descuentososunc(mesingreso,	anioingreso,nroliquidacion,legajosiu,nrocargo,nroconcepto,importe,tipodoc,nrodoc)
	VALUES (relosdtos.limes, relosdtos.lianio,
 
relosdtos.idliquidacion,relosdtos.legajosiu,relosdtos.idcargo,relosdtos.idconcepto,relosdtos.importe,relosdtos.idtipodocumento,relosdtos.penrodoc);

 

FETCH closdtos INTO relosdtos;
END LOOP;
CLOSE closdtos;
	

--llamo al sp que ingresa los datos de los descuentos de los empleados de farmacia
PERFORM agregardescuentosconceptossosuncempfarmacia('farmacia');
return 'true';
END;$function$
