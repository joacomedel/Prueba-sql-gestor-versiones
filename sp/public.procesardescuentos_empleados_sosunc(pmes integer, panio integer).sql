CREATE OR REPLACE FUNCTION public.procesardescuentos_empleados_sosunc(pmes integer, panio integer)
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
OPEN closdtos FOR SELECT penrodoc,idtipodocumento,idconcepto,  round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) as importe, 
		 t.idcargo,t.legajosiu, idliquidacion,limes,lianio,tdnombre,codescripcion,idliquidacion 
		 FROM ca.liquidacion NATURAL JOIN ca.liquidacionempleado 
		 NATURAL JOIN ca.conceptoempleado NATURAL JOIN ca.concepto 
		 NATURAL JOIN ca.empleado NATURAL JOIN ca.persona 	
		 JOIN (SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu 
		 FROM cargo 
		 WHERE  iddepen='SOS' 
		 GROUP BY nrodoc,tipodoc,legajosiu order by nrodoc) as t  ON(t.tipodoc=idtipodocumento and t.nrodoc=penrodoc) 
		 NATURAL JOIN ca.tipodocumento 
                 LEFT JOIN informedescuentoplanillav2 AS idp ON (idliquidacion=idp.nroliquidacion AND t.legajosiu=idp.legajosiu 
                      AND idconcepto=idp.concepto AND  t.idcargo=idp.idcargo AND 
                       round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2)=idp.importe  
			AND pmes =mes AND  panio=anio)
		 WHERE limes=pmes and lianio= panio AND 
nullvalue(idp.idinforme) and round( (ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje )::numeric,2) >0.01
		 AND( idconcepto=388 or idconcepto=387 OR idconcepto=373 OR idconcepto=360 OR idconcepto=374 );
   	
FETCH closdtos INTO relosdtos;
WHILE  FOUND LOOP
	INSERT INTO descuentososunc(mesingreso,	anioingreso,nroliquidacion,legajosiu,nrocargo,nroconcepto,importe,tipodoc,nrodoc)
	VALUES (pmes,panio,relosdtos.idliquidacion,relosdtos.legajosiu,relosdtos.idcargo,relosdtos.idconcepto,relosdtos.importe,relosdtos.idtipodocumento,relosdtos.penrodoc);

FETCH closdtos INTO relosdtos;
END LOOP;
CLOSE closdtos;
	

--llamo al sp que ingresa los datos de los descuentos de los empleados de SOSUNC
PERFORM agregardescuentosconceptossosunc(pmes,panio);
return 'true';
END;

$function$
