CREATE OR REPLACE FUNCTION ca.f_estimulocapacitacion2019(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       rcatemp record;
       rlicmaternidad record;
       datomonto record;
       datoporcentaje record;
       datoaux record;
       rcatsubrogancia record;
       rdiasbasico record;
       codliquidacion integer; 


BEGIN
    --reemplazarparametros
    --(integer, integer, integer, integer, varchar)
    /*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

     codliquidacion = $1;

     elmonto = 0;	

    --busca la categoria de revista del empleado
    -- busco el idliquidacion del sueldo correspondiente a ese mes
    IF($2 = 3) THEN
          SELECT INTO codliquidacion idliquidacion
          FROM ca.liquidacion 
          WHERE idliquidaciontipo  = 1  
                and (limes,lianio) IN(
                          SELECT limes,lianio
                          FROM ca.liquidacion 
                          WHERE idliquidacion = $1 )
          ;
   END IF;

    SELECT INTO rcatemp idcategoria,(cemonto* ceporcentaje) as imp_bas_prop,cemonto , ceporcentaje
    FROM ca.categoriaempleado
    JOIN ca.conceptoempleado USING(idpersona)
    WHERE idpersona = $3 
          and idcategoriatipo = 1 -- VAS ya que se debe anaizar la categoria de revista del empleado
          and nullvalue(cefechafin)
          and idliquidacion= codliquidacion
          and idconcepto = 1; -- basico
                     
    SELECT INTO rdiasbasico *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= codliquidacion
          and idconcepto = 1045; -- Dias laborables mensuales	

    if found then    

RAISE NOTICE 'rcatemp.idcategoria(%)', rcatemp.idcategoria;
    
		if(rcatemp.idcategoria=7) then  -- Categoría 7    27% del Salario Básico
	 
			elmonto = 0;         
		end if;
		if(rcatemp.idcategoria=6) then -- Categoría 6    23% del Salario Básico
			elmonto =0;         
		end if;
		if(rcatemp.idcategoria=5) then -- Categoría 5    14% del Salario Básico
			elmonto = 0;       
		end if;
		if(rcatemp.idcategoria=4) then
			elmonto=(3600/rdiasbasico.ceporcentaje)*rcatemp.ceporcentaje;         
		end if;
		if(rcatemp.idcategoria=3) then
			elmonto=(4000/rdiasbasico.ceporcentaje)*rcatemp.ceporcentaje;         
		end if;
		if(rcatemp.idcategoria=2) then
			elmonto=(4400/rdiasbasico.ceporcentaje)*rcatemp.ceporcentaje;                  
		end if;
		if(rcatemp.idcategoria=1) then
			elmonto=(4800/rdiasbasico.ceporcentaje)*rcatemp.ceporcentaje;                  
		end if;
  END IF;
   
  IF( $2 = 3) THEN --Aguinaldo - SOSUNC
           elmonto = elmonto/2;
  END IF;
return round(elmonto::numeric,3);  
END;
$function$
