CREATE OR REPLACE FUNCTION ca.f_adicionalxgrado(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       valor1139  DOUBLE PRECISION;
       rcatemp record;
       rlicmaternidad record;
       datomonto record;
       datoporcentaje record;
       datoaux record;
       rcatsubrogancia record;
       rdiasbasico record;
       datoliq  record;
 

BEGIN
    --reemplazarparametros
    --(integer, integer, integer, integer, varchar)
    /*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
     -- inicializo pr defecto el montoen 2000
     -- Dani agrego el 26-10-2017 para poder calcular el monto proporcional a losdias trabjados
     -- este es el monto por defecto
     -- elmonto=2000;

valor1139 =0;
select into datoliq * from ca.liquidacion where idliquidacion=$1;
    SELECT INTO datoaux * FROM ca.concepto WHERE idconcepto = 1211;

    --busca la categoria de revista del empleado
  
    
  
    select  into valor1139 * from ca.conceptovalor(datoliq.limes,datoliq.lianio,$3,1139);
    RAISE NOTICE '>>>>>>>>Llamada al valor1139  %',valor1139 ;
SELECT INTO rcatemp idcategoria, ca.f_basicocategoriaxdiastrabajados($1,$2,$3,$4) as imp_bas_prop
   
    FROM ca.categoriaempleado
    natural JOIN ca.categoriatipoliquidacion  
    natural join ca.liquidacion
    WHERE idpersona = $3 
          and idcategoriatipo = 1 -- VAS ya que se debe anaizar la categoria de revista del empleado
          /*Dani comento el 300523 y reeemplazo por las lineas de abajo*/
          /*and (nullvalue(cefechafin)or cefechafin >to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date )*/
           
          and  to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month' > cefechainicio
           and  (nullvalue(cefechafin) or to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date <=cefechafin )
  
          and idliquidacion= $1;
    


 RAISE NOTICE '>>>>>>>>Llamada al f_basicocategoriaxdiastrabajados  %',rcatemp.imp_bas_prop;

    SELECT INTO rdiasbasico *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 1045; -- Dias laborables mensuales	


    

    if found then    
		if(rcatemp.idcategoria=7) then  -- Categoría 7    27% del Salario Básico
			elmonto = (rcatemp.imp_bas_prop+valor1139 ) * 0.27;         
		end if;
		if(rcatemp.idcategoria=6) then -- Categoría 6    23% del Salario Básico
			elmonto = (rcatemp.imp_bas_prop+valor1139 ) * 0.23;         
		end if;
		if(rcatemp.idcategoria=5) then -- Categoría 5    14% del Salario Básico
			elmonto = (rcatemp.imp_bas_prop+valor1139 ) * 0.14;       
		end if;
		

                if(rcatemp.idcategoria=4) then -- Categoría 4    11% del Salario Básico
                        elmonto = (rcatemp.imp_bas_prop+valor1139 )* 0.11;  

  RAISE NOTICE '>>>>>>>>Llamada al (rcatemp.imp_bas_prop+valor1139 )* 0.11   %',elmonto ;
                end if;
                if(rcatemp.idcategoria=3) then -- Categoría 3    8% del Salario Básico
                        elmonto =(rcatemp.imp_bas_prop+valor1139 ) * 0.08;  
                end if;
                if(rcatemp.idcategoria=2) then -- Categoría 2    7% del Salario Básico
                        elmonto = (rcatemp.imp_bas_prop+valor1139 ) * 0.07;  
                end if;
                if(rcatemp.idcategoria=1) then -- Categoría 1    6% del Salario Básico
                        elmonto = (rcatemp.imp_bas_prop+valor1139 ) * 0.06;  
                end if; 
  END IF;
return round(elmonto::numeric,3);  
END;
$function$
