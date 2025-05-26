CREATE OR REPLACE FUNCTION ca.f_adicionalconectividad(integer, integer, integer, integer)
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
       categemp  record;
       propor record;
       rdiasbasico  record;
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
   
   SELECT  INTO categemp  cefechainicio
   FROM ca.categoriaempleado WHERE idcategoriatipo=2 and idpersona =  $3 and 
   ( nullvalue(cefechafin)  or   
  to_date(concat(rliquidacion.lianio,'-',rliquidacion.limes,'-1'),'YYYY-MM-DD')<=cefechafin );

if found then elmonto=0;   /*si subroga no le corresponde adicional por conectividad*/
else

/*Dani agrego el 2021-11-25 ,calculo el proporcional del concepto de acuerdo a los dias trabajados por pedido de JulietaE.*/

SELECT INTO propor *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 998; -- Dias trabajados


    

                 
    SELECT INTO rdiasbasico *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 1045; -- Dias laborables mensuales	


    





                if(rcatemp.idcategoria=5) then  -- Categoría 5 
	        	elmonto = (1000/rdiasbasico.ceporcentaje) *propor.ceporcentaje;         
		end if;
                if(rcatemp.idcategoria=6) then -- Categoría 6	  
			elmonto = (1500/rdiasbasico.ceporcentaje) *propor.ceporcentaje;         
		end if;
		if(rcatemp.idcategoria=7) then -- Categoría 7 	
			elmonto = (2000/rdiasbasico.ceporcentaje) *propor.ceporcentaje;   
                 end if;
end if;


  
return round(elmonto::numeric,3);  
END;
$function$
