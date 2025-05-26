CREATE OR REPLACE FUNCTION ca.f_garantiasalarial(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       proporcion DOUBLE PRECISION;
       rcatemp record;
       rlicmaternidad record;
       datomonto record;
       datoporcentaje record;
       datoaux record;
       rcatsubrogancia record;
       rconcepto record;
       rliquidacion record;
       rconceptoaux record;
       rconcepto2 record;
       rconcepto3  record;
BEGIN
  
    /*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
    
      proporcion = 1;
     elmonto = 0;	

     SELECT INTO rliquidacion * FROM ca.liquidacion   WHERE  idliquidacion= $1;

    --busca la categoria de revista del empleado
  
    SELECT INTO rcatemp idcategoria,(cemonto* ceporcentaje) as imp_bas_prop,cemonto , ceporcentaje
    FROM ca.categoriaempleado
    JOIN ca.conceptoempleado USING(idpersona)
    WHERE idpersona = $3 
          and idcategoriatipo = 1 --  se debe analizar la categoria de revista del empleado
         and (
 date_trunc('month', concat(rliquidacion.lianio,'-',rliquidacion.limes,'-1')::date) <= cefechafin or nullvalue(cefechafin)
        )  
          and idliquidacion= $1
          and idconcepto = 1; -- basico


 --busca la categoria de subrogancia del empleado, si es que la tiene
  

SELECT INTO rcatsubrogancia idcategoria,(cemonto* ceporcentaje) as imp_bas_prop,cemonto , ceporcentaje
    FROM ca.categoriaempleado
    JOIN ca.conceptoempleado USING(idpersona)
    WHERE idpersona = $3 
          and idcategoriatipo = 2 --  se debe analizar la categoria de revista del empleado
         and (
 date_trunc('month', concat(rliquidacion.lianio,'-',rliquidacion.limes,'-1')::date) <= cefechafin or nullvalue(cefechafin)
        )  
          and idliquidacion= $1
          and idconcepto = 1; -- basico



                     
    SELECT INTO rconcepto *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 100; -- Horas asignadas a la jornada

 SELECT INTO rconcepto3 *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and ( idconcepto=1045);  

  SELECT INTO rconcepto2 *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 998; -- Dias Trabajados


    if found then  


      SELECT INTO rconceptoaux *
      FROM ca.conceptoempleado 
      WHERE idpersona = $3  and idliquidacion= $1   and idconcepto = 17 and ceporcentaje<>0; -- Suplemento por mayor responsabilidad

     --     if (not found) then --si no tiene el concepto suplemento mayor responsabilidad entonces si corresponde liquidar el 1288
     -- Por pedido de JE el 23042025 se el concepto 1288 se liquida para una persona q tenga la categoria X ya sea de revista o de subrogancia. Tiene q ser mayor o igual a 4
     -- verifica si trabaja horario reducido o si trabajo menos dias q el total configurado  
                
                IF  ((rconcepto.cemonto <> rconcepto.ceporcentaje and (rconcepto.cemonto/rconcepto.ceporcentaje)<0.75))
                      THEN               
                            -- proporcion = 0.66625;
                              proporcion =rconcepto.cemonto/rconcepto.ceporcentaje;
                END IF;

                IF  (rconcepto2.ceporcentaje<30 ) --menos de 30 dias trabajados
                  then
                            proporcion = (rconcepto2.ceporcentaje/rconcepto3.ceporcentaje)*proporcion; 
                END IF;
 
 
 
if ((rcatsubrogancia.idcategoria) is null) then 
                IF(rcatemp.idcategoria=7) then  -- Categoría 7
                        IF ($4 = 1288) then 
                                elmonto = 220000* proporcion; 
                         END IF;
                       IF ($4 = 1289) then 
                                elmonto = 1010000 * proporcion;   
                              
                         END IF;
                       
                            
		end if;


                IF(rcatemp.idcategoria=6 ) then -- Categoría 6
                     
                         if($4 = 1288) then 
                               elmonto = 150000* proporcion; 
                         END IF;
                        if($4 = 1289) then 
                                elmonto =  565000 * proporcion;
                         END IF;
		
                                
		 END IF;
               IF(rcatemp.idcategoria=5 ) then -- Categoría 5

                         if($4 = 1288) then 
                               elmonto = 100000* proporcion; 
                         END IF;
                        
		 
		END IF;
                IF( rcatemp.idcategoria=4 ) then -- Categoría 4

                         if($4 = 1288) then 
                               elmonto = 70000* proporcion; 
                         END IF;
                         
		END IF;
		
 
         --END IF;
else    --if ((rcatsubrogancia.idcategoria) is null)  

                   IF(rcatsubrogancia.idcategoria=6 ) then -- Categoría 6
                     
                         if($4 = 1288) then 
                               elmonto = 150000* proporcion; 
                         END IF;
                        if($4 = 1289) then 
                                elmonto =  565000 * proporcion;
                         END IF;
		
                        
		    END IF;
                  IF(rcatsubrogancia.idcategoria=5 ) then -- Categoría 5

                         if($4 = 1288) then 
                               elmonto = 100000* proporcion; 
                         END IF;
                        
		 
		   END IF;
                IF( rcatsubrogancia.idcategoria=4 ) then -- Categoría 4

                         if($4 = 1288) then 
                               elmonto = 70000* proporcion; 
                         END IF;
                         
		END IF;


END IF;--if ((rcatsubrogancia.idcategoria) is null) then 
  end if;
return round(elmonto::numeric,3);  
END;
$function$
