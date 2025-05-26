CREATE OR REPLACE FUNCTION ca.f_farmactaacuerdo062023(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       proporcion DOUBLE PRECISION;
       elmontotope  record;
       rcatemp record;
       rlicmaternidad record;
  
       datomonto record;
       datoporcentaje record;
       datoaux record;
       rcatsubrogancia record;
       rconcepto record;
       rconcepto2 record;
       rconcepto3 record;
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

SELECT INTO rconcepto2 *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and ( idconcepto=998);     --Dias trabajados



   SELECT INTO rconcepto3 *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and ( idconcepto=1045);     --Dias laborables mensuales



   /*esto es para buscar si la persona trabajo jornada completa o no */                  
    SELECT INTO rconcepto *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 1136; -- Horas mensuales 

     
                RAISE NOTICE 'rcatemp.idcategoria(%)', rcatemp.idcategoria;
                proporcion = 1;
              /*Se comenta la proporcion por pedido de JE 290523 no debe existir mas la consideracion del proporcional*/
              /*Segun mail del 22062023 JE ratifica que se debe colocar el proporcional*/
  IF  (rconcepto.cemonto <> rconcepto.ceporcentaje and (rconcepto.cemonto/rconcepto.ceporcentaje)<0.75) --jornada reducida
  then 
                            proporcion =rconcepto.cemonto/rconcepto.ceporcentaje;
  END IF; 
                
  IF  (rconcepto2.ceporcentaje<30 ) --menos de 30 dias trabajados
  then
                           proporcion =rconcepto2.ceporcentaje/rconcepto3.ceporcentaje; 
  END IF;
    

   select into elmontotope * FROM ca.conceptotope  
                                             WHERE  idconcepto = 1285 and idcategoria=rcatemp.idcategoria
                                          and nullvalue(ctfechahasta);
 
                if(rcatemp.idcategoria=15) then  -- Categoría 15 Ayudante en Gestión de Farmacia  
	        	 
 
                   elmonto =elmontotope.ctmontominimo    * proporcion;  
		end if;
                if(rcatemp.idcategoria=16) then -- Categoría 16	Personal en Gestión de Farmacia  
			 
			     elmonto =elmontotope.ctmontominimo    * proporcion;  
		end if;
		if(rcatemp.idcategoria=17 or rcatemp.idcategoria=18) then -- Categoría 17  Farmaceutico  Categoria 18 Farmaceutico Auxiliar
			 
			    elmonto =elmontotope.ctmontominimo    * proporcion;  
                 end if;
 
 


 
  
return round(elmonto::numeric,3);  
END;
$function$
