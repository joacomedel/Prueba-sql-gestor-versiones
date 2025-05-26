CREATE OR REPLACE FUNCTION ca.adicionalconectividad(integer, integer, integer, integer)
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
          and idliquidacion= $1; -- basico           
   
   

                if(rcatemp.idcategoria=5) then  -- Categoría 5 
	        	elmonto = 1000;         
		end if;
                if(rcatemp.idcategoria=6) then -- Categoría 6	  
			elmonto = 1500;         
		end if;
		if(rcatemp.idcategoria=7) then -- Categoría 7 	
			elmonto = 2000;   
                 end if;


  
return round(elmonto::numeric,3);  
END;
$function$
