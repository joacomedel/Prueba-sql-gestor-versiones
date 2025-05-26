CREATE OR REPLACE FUNCTION ca.f_farmasumaextraesencial(integer, integer, integer, integer)
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



BEGIN
  
    /*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
    

     elmonto = 0;	


     SELECT INTO rliquidacion * FROM ca.liquidacion   WHERE  idliquidacion= $1;

    --busca la categoria de revista del empleado
  
    SELECT INTO rcatemp idcategoria,(cemonto* ceporcentaje) as imp_bas_prop,cemonto , ceporcentaje
    FROM ca.categoriaempleado
    JOIN ca.conceptoempleado USING(idpersona)
    WHERE idpersona = $3 
          and idcategoriatipo = 1 -- VAS ya que se debe anaizar la categoria de revista del empleado
         and (
 date_trunc('month', concat(rliquidacion.lianio,'-',rliquidacion.limes,'-1')::date) <= cefechafin or nullvalue(cefechafin)
        )  
          and idliquidacion= $1
          and idconcepto = 1028; -- basico
                     
    SELECT INTO rconcepto *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 1136; -- Horas mensuales 

    if found then    
        
                RAISE NOTICE 'rcatemp.idcategoria(%)', rcatemp.idcategoria;
                proporcion = 1;
                IF  (rconcepto.cemonto <> rconcepto.ceporcentaje 
                 and (rconcepto.cemonto/rconcepto.ceporcentaje)<0.75) THEN               
                             proporcion = 0.66625;
                END IF;
    
	
    if(rcatemp.idcategoria=15) then  -- Categoría 15 Ayudante en Gestión de Farmacia  
	        	elmonto = 2068* proporcion;         
		end if;
		if(rcatemp.idcategoria=16) then -- Categoría 16	Personal en Gestión de Farmacia  
			elmonto =2530* proporcion;         
		end if;
		if(rcatemp.idcategoria=17) then -- Categoría 17 	Farmaceutico  
			elmonto = 2800* proporcion;   
                 end if;




  END IF;
  
return round(elmonto::numeric,3);  
END;
$function$
