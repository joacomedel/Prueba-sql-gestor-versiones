CREATE OR REPLACE FUNCTION ca.f_suplementopremio(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       CantDiasBasicos DOUBLE PRECISION;
       CantDiaslaborables  DOUBLE PRECISION;
       cantDiasConSup DOUBLE PRECISION;
       diasConSup record;
       rcapremiomonto record;
       rconsup record;
       laliq record;
       csuperior refcursor;  
       acumuladormontosup DOUBLE PRECISION;
       acumuladodias DOUBLE PRECISION;
       cantdiasmes integer;
       categemp   date;

valordia DOUBLE PRECISION;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

   --f_funcion(#,&, ?,@)
   --Obtiene dias correspondientes al basico   
   SELECT into CantDiasBasicos ceporcentaje   
   FROM ca.conceptoempleado WHERE idconcepto=1084 and idliquidacion=$1 and idpersona = $3; 
    RAISE NOTICE 'CantDiasBasicos (%) ',CantDiasBasicos ;
  
--obtiene dias laborables mensuales
 SELECT into CantDiaslaborables ceporcentaje   
   FROM ca.conceptoempleado WHERE idconcepto=1045 and idliquidacion=$1 and idpersona = $3; 
 
 
/*obtengo anio y mes de la liquidacion*/
    SELECT  INTO laliq *   FROM ca.liquidacion WHERE idliquidacion=$1;


 
 
 
 /*obtengo la categoria de subrogancia del empleado*/
SELECT  INTO categemp  cefechainicio
   FROM ca.categoriaempleado WHERE idcategoriatipo=2 and idpersona =  $3 and 
   ( nullvalue(cefechafin)  or   
  to_date(concat(laliq.lianio,'-',laliq.limes,'-1'),'YYYY-MM-DD')+ interval '1 month'- interval '1 day'<=cefechafin );


SELECT  into cantdiasmes
    DATE_PART('days', 
        DATE_TRUNC('month', NOW()) 
        + '1 MONTH'::INTERVAL 
        - DATE_TRUNC('month', NOW())
    ) as cantdiasmes;

 
 
 
 
 
 
/*obtiene el premio de revista*/

SELECT into rcapremiomonto *
            FROM ca.persona
            NATURAL JOIN ca.categoriaempleado
            NATURAL JOIN ca.categoriatipoliquidacion
            NATURAL JOIN ca.categoriatipo
            NATURAL JOIN ca.liquidacion
            WHERE idpersona = $3 
                  and idliquidaciontipo= $2 and idliquidacion = $1
              
and cefechainicio < to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month'  -- fecha inicio cat menor al primer dia del mes siguiente

                  and  ( nullvalue(cefechafin)   or  cefechafin >= concat(lianio,'/' ,limes ,'/01')::date)
                             
                   and idcategoriatipo = 1;

  RAISE NOTICE 'MONTO PRemio revista (%)',rcapremiomonto.capremiomonto ;
/*obtienen los premios por cada subrogancia*/
/*open csuperior for  SELECT  capremiomonto,idcategoria as idcategsubroga */
open csuperior for SELECT   distinct(idcategoria) as idcategsubroga ,capremiomonto
            FROM ca.persona
            NATURAL JOIN ca.categoriaempleado
            NATURAL JOIN ca.categoriatipoliquidacion
            NATURAL JOIN ca.categoriatipo
            NATURAL JOIN ca.liquidacion
            WHERE idpersona = $3 
                  and idliquidaciontipo= $2 and idliquidacion = $1                                  
                 and cefechainicio < to_timestamp(concat(lianio,'-',limes,'-1') ,
                 'YYYY-MM-DD')::date+ interval '1 month'  -- fecha inicio cat menor al primer dia del mes siguiente

                  and  ( nullvalue(cefechafin)   or  cefechafin >= concat(lianio,'/' ,limes ,'/01')::date)
                  and idcategoriatipo = 2 ; 

        acumuladodias = 0;
        acumuladormontosup=0;
        fetch csuperior into rconsup;
        WHILE  found LOOP
                  
                 --obtengo la cantidad de dias que tiene con categoria de subrogancia modif vas 29-05-2018
                  select into cantDiasConSup sum(valor)
from
( SELECT  
                               
                         CASE WHEN 
     (nullvalue(cefechafin) or cefechafin >=  to_timestamp(concat(lianio,'-',limes,'-1') ,
     'YYYY-MM- DD')::date+ interval '1 month' )
     THEN ((to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date+ interval 
     '1 month')::date  - cefechainicio)
     WHEN (cefechafin<= (to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date
     + interval '1 month')::date
    and cefechafin >=(to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date)
    and cefechainicio <=(to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date)
   ) THEN

   (cefechafin - to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date)+1

   ELSE
             (cefechafin - cefechainicio)+1   END as valor
                   FROM ca.persona
                   NATURAL JOIN ca.categoriaempleado
                   NATURAL JOIN ca.categoriatipoliquidacion
                   NATURAL JOIN ca.categoriatipo
                   NATURAL JOIN ca.liquidacion
                   WHERE idpersona = $3
                        and idcategoriatipo = 2
                        and idliquidaciontipo= $2 and idliquidacion = $1
                        and idcategoria = rconsup.idcategsubroga
                        and cefechainicio < to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month'
                        and  ( nullvalue(cefechafin)   or  cefechafin >= concat(lianio,'/' ,limes ,'/01')::date) ) as t;
      
                   SELECT into CantDiasBasicos ceporcentaje
                   FROM ca.conceptoempleado WHERE idconcepto=1084 and idliquidacion=$1 and idpersona = $3 ;
                   
                   if  ((cantDiasConSup  >  CantDiasBasicos)
                   or  (cantdiasmes=cantDiasConSup   
    and categemp::date >= concat(laliq.lianio,'-',laliq.limes,'-','1')::date ) )THEN
                                 cantDiasConSup = CantDiasBasicos;
                   END IF;
  RAISE NOTICE 'MONTO subroga categoria (%) monto (%) cantDiasConSup (%)',rconsup.idcategsubroga ,rconsup.capremiomonto,cantDiasConSup ;
                   
if CantDiaslaborables >CantDiasBasicos  then 
valordia = (abs(abs(rconsup.capremiomonto) - abs(rcapremiomonto.capremiomonto))/CantDiaslaborables );
else
valordia = (abs(abs(rconsup.capremiomonto) - abs(rcapremiomonto.capremiomonto))/CantDiasBasicos );
END IF;
  RAISE NOTICE 'MONTO diferencia suplemento (%) ', abs(abs(rconsup.capremiomonto) - abs(rcapremiomonto.capremiomonto));
  RAISE NOTICE 'Dias basicos  (%) ', CantDiasBasicos;

 RAISE NOTICE 'valordia(%)',valordia;
                   acumuladormontosup =  acumuladormontosup  
                                     + valordia * cantDiasConSup;
                   acumuladodias = acumuladodias + cantDiasConSup;

       fetch csuperior into rconsup;
       end loop; 
       close csuperior;
 RAISE NOTICE 'acumuladormontosup (%)  ',acumuladormontosup;
 RAISE NOTICE 'acumuladodias (%)  ',acumuladodias;
      if(acumuladodias>30) then acumuladodias=30;
      END IF;
      UPDATE ca.conceptoempleado SET ceporcentaje = acumuladodias
      WHERE  idconcepto=33 and idliquidacion=$1 and idpersona = $3;

      --Dani agrego el 15/01/18 para q contemtple el caso de calculr conceptos para empleados q no trabajaron ningun dia del mes pero a los cuales se les necesitaba hacer una liquidacion final, por ejemplo el caso de Liliana Molinas de Copahue.
      if (acumuladormontosup<>0) then

                    elmonto =round ((acumuladormontosup/acumuladodias) ::numeric,3);
      else 
                   elmonto=0;
      END IF;



      -- ACTUALIZO EL monto para guardar el importe dia correspondiente al suplemento
      UPDATE ca.conceptoempleado SET cemonto =elmonto
      WHERE idconcepto=33 and idliquidacion=$1 and idpersona = $3;

      return elmonto;

END;
$function$
