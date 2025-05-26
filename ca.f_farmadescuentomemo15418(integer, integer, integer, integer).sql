CREATE OR REPLACE FUNCTION ca.f_farmadescuentomemo15418(integer, integer, integer, integer)
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


BEGIN
  
    /*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
    

   elmonto = 0;	

    SELECT INTO rdiasbasico *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 1045; -- Dias laborables mensuales	

    --busca la categoria de revista del empleado
  
    SELECT INTO rcatemp idcategoria,(cemonto* ceporcentaje) as imp_bas_prop,cemonto , ceporcentaje
    FROM ca.categoriaempleado
    JOIN ca.conceptoempleado USING(idpersona)
    WHERE idpersona = $3 
          and idcategoriatipo = 1 -- VAS ya que se debe anaizar la categoria de revista del empleado
          and nullvalue(cefechafin)
          and idliquidacion= $1
          and idconcepto = 1028; -- basico
                     
  
    if found then    

           RAISE NOTICE 'rcatemp.idcategoria(%)', rcatemp.idcategoria;
           elmonto = rcatemp.cemonto/2;
    
		
  END IF;
  
return round(elmonto::numeric,3);  
END;
$function$
