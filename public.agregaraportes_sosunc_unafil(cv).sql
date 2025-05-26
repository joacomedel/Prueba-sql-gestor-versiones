CREATE OR REPLACE FUNCTION public.agregaraportes_sosunc_unafil(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Carga los aportes de lOS Empleados de SOSUNC, utilizando la informacion de las tablas DE LIquidacion de Sueldos
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
/*Dani agrego el 23082021 para que agregue a los pasantes, a los cuales no se les liquidada el concepto 202*/                     
                     natural join 
                         (select idcategoria,idpersona from
                                ca.categoriaempleado
                                  where  nullvalue(cefechafin) 
                                  or concat(date_part('year', current_date - 30),'-',/*lpad(date_part('month', current_date - 30),2,'0')  */'-01','-01')<=cefechafin
                         )as datoscategoria
                     NATURAL JOIN ca.persona JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu		
                                                    FROM cargo WHERE fechainilab<= CURRENT_DATE 
                                                    and fechafinlab >=	CURRENT_DATE and iddepen='SOS'		
                                                    GROUP BY nrodoc,tipodoc,legajosiu		
                                                    ORDER BY nrodoc) as t  on (t.tipodoc=idtipodocumento and t.nrodoc=penrodoc) 
                      NATURAL JOIN ca.tipodocumento	
                      LEFT JOIN dh21 ON(limes = mesingreso AND lianio=anioingreso AND nroliquidacion=(32*1000000)+idliquidacion AND
                        case when (t.idcargo<990000) then (990000 +t.idcargo::numeric)  else  t.idcargo end=nrolegajo AND  
                         ca.conceptoempleado.idconcepto=dh21.nroconcepto)

                      WHERE  
               (legajosiu=$1  )         and lianio=2025  

   

                             
/*Dani agrego el 23082021 para que agregue a los pasantes, a los cuales no se les liquidada el concepto 202*/                     

AND  (
((idconcepto=202 or idconcepto=1248) AND nullvalue(dh21.nroconcepto))
or
((datoscategoria.idcategoria=21)and idconcepto=1232)-- esto es para tener en cuenta los pasantes
);
                    

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
                  apellidoynombre,
                   cuil )
SELECT limes,lianio,case when (t.idcargo<990000) then (990000 +t.idcargo::numeric)  else  t.idcargo end  as idcargo,
                     cefechainicio, CASE WHEN nullvalue(fechafinlab) THEN fechafinlab ELSE fechafinlab END,idcategoria,
                     'SOS',case when (t.idcargo<990000) then (990000 +t.idcargo::numeric)  else  t.idcargo end  as legajo,
                     'PERM', lianio,limes, round((ca.conceptoempleado.cemonto*ca.conceptoempleado.ceporcentaje)::numeric,2) as importe,  
                     (32*1000000)+idliquidacion,'N', concat(ca.persona.peapellido ,', ' , ca.persona.penombre),replace(replace(penrocuil,'-',''),' ','')as cuil
                     FROM ca.liquidacion NATURAL JOIN ca.liquidacionempleado NATURAL JOIN ca.conceptoempleado 
                     NATURAL JOIN ca.concepto	NATURAL JOIN ca.empleado 
/*Dani agrego el 23082021 para que agregue a los pasantes, a los cuales no se les liquidada el concepto 202*/                     
                     natural join 
                         (select idcategoria,idpersona from
                                ca.categoriaempleado
                                  where  nullvalue(cefechafin) 
                                  or concat(date_part('year', current_date - 30),'-',/*lpad(date_part('month', current_date - 30),2,'0') */'-01','-01')<=cefechafin
                         )as datoscategoria

                     NATURAL JOIN ca.categoriaempleado
                     NATURAL JOIN ca.persona JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu,fechainilab,fechafinlab	
                                                    FROM cargo WHERE fechainilab<= CURRENT_DATE 
                                                    and fechafinlab >=	CURRENT_DATE and iddepen='SOS'		
                                                    GROUP BY nrodoc,tipodoc,legajosiu,fechainilab,fechafinlab		
                                                    ORDER BY nrodoc) as t  on (t.tipodoc=idtipodocumento and t.nrodoc=penrodoc) 
                      NATURAL JOIN ca.tipodocumento	
                      LEFT JOIN dh49 ON(limes = mesingreso AND lianio=anioingreso AND nroliquidacion=(32*1000000)+idliquidacion AND
                      t.idcargo=nrolegajo AND case when (t.idcargo<990000) then (990000 +t.idcargo::numeric)  else  t.idcargo end =nrocargo)
                      WHERE 
                          (legajosiu=$1  )         and lianio=2025
  
    
 
AND  (
((idconcepto=202 or idconcepto=1248) AND nullvalue(dh49.nrocargo))
or
((datoscategoria.idcategoria=21)and idconcepto=1232)-- esto es para tener en cuenta los pasantes  

)
;
    

return true;

END;
$function$
