CREATE OR REPLACE FUNCTION public.ingresararchivosaportes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
Carga la informacion de los archivos DH21 y DH49
*/
DECLARE
--CURSOR
    cursorauxi refcursor;

--RECORD
    elemcursor RECORD;
    rliquidacion RECORD;

--VARIABLES 
    resultado boolean;
	
BEGIN





INSERT INTO dh21(mesingreso,anioingreso,nroliquidacion,nrolegajo,nroconcepto,importe,codigoescalafon,unidadacademica,nrocargo)  

SELECT limes,lianio,(32*1000000)+idliquidacion,  case when (t.idcargo<990000) then (990000 +t.idcargo::numeric)  else  t.idcargo end  as legajo,
                     idconcepto,round((ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje)::numeric,2) as importe,  
                     'SOS','SOS',
                     case when (t.idcargo<990000) then (990000 +t.idcargo::numeric)  else  t.idcargo end  as idcargo
                     FROM ca.liquidacion NATURAL JOIN ca.liquidacionempleado NATURAL JOIN ca.conceptoempleado 
                     NATURAL JOIN ca.concepto	NATURAL JOIN ca.empleado 	
                     NATURAL JOIN ca.persona JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu		
                                                    FROM cargo WHERE fechainilab<= CURRENT_DATE 
                                                    and fechafinlab >=	CURRENT_DATE and iddepen='SOS'		
                                                    GROUP BY nrodoc,tipodoc,legajosiu		
                                                    ORDER BY nrodoc) as t  on (t.tipodoc=idtipodocumento and t.nrodoc=penrodoc) 
                      NATURAL JOIN ca.tipodocumento	
                      LEFT JOIN dh21 ON(limes = mesingreso AND lianio=anioingreso AND nroliquidacion=idliquidacion AND
                        t.idcargo=nrolegajo AND idconcepto=nroconcepto)
                      WHERE limes=date_part('month', current_date -30) and lianio=date_part('year', current_date - 30) and (idconcepto=202);

INSERT INTO  dh49(mesingreso,
 		  anioingreso,
                  nrocargo,
                  fechaalta,
                  fechabaja,
                  categoria,
                  unidadacademica,
                  nrolegajo,
                  codcaracteristica,
                  anioliquidacion,
                  mesliquidacion,
                  importebruto,
                  nroliquidacion,
                  tipoescalafon,
                  apellidoynombre )
SELECT limes,lianio,case when (t.idcargo<990000) then (990000 +t.idcargo::numeric)  else  t.idcargo end  as idcargo,
                     cefechainicio, CASE WHEN nullvalue(fechafinlab) THEN fechafinlab ELSE fechafinlab END,idcategoria,
                     'SOS',case when (t.idcargo<990000) then (990000 +t.idcargo::numeric)  else  t.idcargo end  as legajo,
                     'PERM', lianio,limes, round((ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje)::numeric,2) as importe,  
                     (32*1000000)+idliquidacion,'N', concat(ca.persona.peapellido ,', ' , ca.persona.penombre)
                     FROM ca.liquidacion NATURAL JOIN ca.liquidacionempleado NATURAL JOIN ca.conceptoempleado 
                     NATURAL JOIN ca.concepto	NATURAL JOIN ca.empleado NATURAL JOIN ca.categoriaempleado
                     NATURAL JOIN ca.persona JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu,fechainilab,fechafinlab	
                                                    FROM cargo WHERE fechainilab<= CURRENT_DATE 
                                                    and fechafinlab >=	CURRENT_DATE and iddepen='SOS'		
                                                    GROUP BY nrodoc,tipodoc,legajosiu,fechainilab,fechafinlab		
                                                    ORDER BY nrodoc) as t  on (t.tipodoc=idtipodocumento and t.nrodoc=penrodoc) 
                      NATURAL JOIN ca.tipodocumento	
                      LEFT JOIN dh21 ON(limes = mesingreso AND lianio=anioingreso AND nroliquidacion=idliquidacion AND
                        t.idcargo=nrolegajo AND idconcepto=nroconcepto)
                      WHERE nullvalue(cefechafin) AND 
                      limes=date_part('month', current_date -30) and lianio=date_part('year', current_date - 30) and (idconcepto=202);


return true;


END;
$function$
