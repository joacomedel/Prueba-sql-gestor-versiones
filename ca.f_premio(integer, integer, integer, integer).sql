CREATE OR REPLACE FUNCTION ca.f_premio(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       horastrab DOUBLE PRECISION;
       fechacompara date;
       diaingreso integer;
       datoliq  record;
       reduccional50 DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
reduccional50 =1;
 
  SELECT INTO fechacompara concat(EXTRACT(YEAR FROM cefechainicio),'-',EXTRACT(MONTH FROM cefechainicio),'-1')::date  fecha
  FROM ca.categoriaempleado

 join ca.afip_situacionrevistaempleado using(idpersona) WHERE idpersona= $3 and idcategoria <>21  and idafip_situacionrevista=1
 order by cefechainicio asc limit 1;

/*Dani comento 27082021 porq no servia para los casos de pasantes que pasaban a planta */
 /*SELECT INTO fechacompara concat(EXTRACT(YEAR FROM emfechadesde),'-',EXTRACT(MONTH FROM emfechadesde),'-1')::date  fecha
  FROM ca.empleado WHERE idpersona= $3;*/

  SELECT INTO datoliq *  FROM ca.liquidacion WHERE idliquidacion= $1;


 SELECT INTO elmonto round ((monto/cantidaddias)::numeric,6)
  FROM ( SELECT CASE WHEN extract(YEAR from
  
         age(to_timestamp(concat(EXTRACT(YEAR FROM CURRENT_TIMESTAMP) ,'-',EXTRACT(MONTH FROM CURRENT_TIMESTAMP),'-1'),'YYYY-MM-DD'),fechacompara)) >=1
	THEN capremiomonto
	WHEN  (extract(MONTH from age(to_timestamp(concat(EXTRACT(YEAR FROM CURRENT_TIMESTAMP),'-',EXTRACT(MONTH FROM CURRENT_TIMESTAMP),'-1'),'YYYY-MM-DD'),fechacompara)) >=3     and
	extract(MONTH from age(to_timestamp(concat(EXTRACT(YEAR FROM CURRENT_TIMESTAMP) ,'-',EXTRACT(MONTH FROM CURRENT_TIMESTAMP),'-1'),'YYYY-MM-DD'),fechacompara)) <6)
	THEN  (0.5* capremiomonto )
	WHEN (extract(MONTH from age(to_timestamp(concat(EXTRACT(YEAR FROM CURRENT_TIMESTAMP) ,'-',EXTRACT(MONTH FROM CURRENT_TIMESTAMP),'-1'),'YYYY-MM-DD'),fechacompara)) ) < 3
	then 0 ELSE capremiomonto  END as monto
    FROM ca.persona
     NATURAL JOIN ca.empleado
	NATURAL JOIN ca.categoriaempleado
	NATURAL JOIN ca.categoriatipoliquidacion
	NATURAL JOIN ca.categoriatipo
	NATURAL JOIN ca.conceptoempleado AS cemp
	WHERE idpersona = $3 and
	idliquidaciontipo=$2       and
	to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month'> cefechainicio   and
	(nullvalue(cefechafin) or to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date<=cefechafin )   and
	idcategoriatipo = 1    and
	idconcepto = 1 and
	idliquidacion= $1
) as T
	NATURAL JOIN
	(SELECT ceporcentaje  as cantidaddias,idpersona
		FROM ca.conceptoempleado
		WHERE idpersona =$3 and
		idconcepto = 1045 and
		idliquidacion=$1
 ) as D;

/* SELECT INTO horastrab round ((cemonto/ceporcentaje)::numeric,2)
		FROM ca.conceptoempleado
 		WHERE  idpersona  = $3 and
		idconcepto = 100 and
		idliquidacion=$1;	
       		
 UPDATE ca.conceptoempleado SET ceporcentaje = (T.ceporcentaje*horastrab)
 FROM  (
 SELECT ceporcentaje
		FROM ca.conceptoempleado
 		WHERE  idpersona  = $3 and
		idconcepto = 998 and
		idliquidacion=$1
 ) as T
 WHERE idpersona  = $3 and
		idconcepto = 4 and
		idliquidacion= $1 ;
*/		
SELECT INTO reduccional50 ceporcentaje
		FROM ca.conceptoempleado
 		WHERE  idpersona  = $3 and
		idconcepto = 0 and
		idliquidacion=$1;	

       		
	
--Dani 26012022 agrego para que devuelva el 50% en el caso de reduccion de sueldo. Caso leg 17, Liq Enero2022
elmonto = elmonto * reduccional50 ;


return elmonto;
END;

/*
 *  SELECT round ((monto/cantidaddias)::numeric,2)as monto FROM ( SELECT CASE WHEN extract(YEAR from age(CURRENT_TIMESTAMP,cefechainicio)) >=1 THEN capremiomonto     WHEN  (extract(MONTH from age(CURRENT_TIMESTAMP,cefechainicio)) >=3     and extract(MONTH from age(CURRENT_TIMESTAMP,cefechainicio)) <6) THEN  (0.5* capremiomonto ) WHEN (extract(MONTH from age(CURRENT_TIMESTAMP,cefechainicio)) ) < 3  then 0 ELSE capremiomonto  END as monto FROM ca.persona NATURAL JOIN ca.categoriaempleado NATURAL JOIN ca.categoriatipoliquidacion NATURAL JOIN ca.categoriatipo NATURAL JOIN ca.conceptoempleado AS cemp WHERE idpersona = ? and idliquidaciontipo=1       and  CURRENT_DATE >= cefechainicio   and  (nullvalue(cefechafin) or CURRENT_DATE <=cefechafin )   and idcategoriatipo = 1    and idconcepto = 1 and idliquidacion= # ) as T    NATURAL JOIN (SELECT ceporcentaje  as cantidaddias,idpersona  FROM ca.conceptoempleado WHERE idpersona =? and   idconcepto = 1045 and  idliquidacion=# ) as D
*/
$function$
