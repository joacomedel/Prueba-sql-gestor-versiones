CREATE OR REPLACE FUNCTION ca.f_farmlicenciavacaciones(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE
       elmonto DOUBLE PRECISION;
       rconcepto record;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_basicocategoria(#,&, ?,@)
 SELECT  INTO elmonto 
case when (nullvalue(diasmes)or diasmes<>0) then  round ((montobasico/diasmes)::numeric,3)
else 0 end as elmonto
   --   SELECT INTO elmonto round ((montobasico/diasmes)::numeric,3)
		FROM ( SELECT SUM(montobasico)as  montobasico , SUM(diasmes)as diasmes
		FROM ( SELECT camonto  as montobasico,0 as diasmes
		        FROM ca.persona
		        NATURAL JOIN ca.categoriaempleado
		        NATURAL JOIN ca.categoriatipoliquidacion
		        NATURAL JOIN ca.categoriatipo
		        WHERE idpersona = $3 and
		        idliquidaciontipo=$2  and
		        CURRENT_DATE >= cefechainicio and
	         	(nullvalue(cefechafin) or CURRENT_DATE <=cefechafin ) and
		      idcategoriatipo = 1
	UNION  SELECT 0 as montobasico, ceporcentaje as diasmes
		FROM ca.conceptoempleado
		WHERE idpersona =$3 and
		idliquidacion=$1   and
		idconcepto=1177   --dias laborables mensuales
 ) as D )as T;  -- dias correspondientes basico
	

    SELECT INTO rconcepto *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 1136; -- Horas mensuales 

                  
     elmonto= elmonto/rconcepto.ceporcentaje *rconcepto.cemonto; 

return 	elmonto;
END;

/*
SELECT  (montobasico/cantidaddias) as monto FROM ( SELECT (cemonto * ceporcentaje) as montobasico,idpersona FROM ca.conceptoempleado WHERE idpersona = ? and   idconcepto = 1044 and  idliquidacion=# ) as M NATURAL JOIN (SELECT ceporcentaje  as cantidaddias,idpersona FROM ca.conceptoempleado WHERE idpersona =? and   idconcepto = 1045 and  idliquidacion=# ) as D

*/
$function$
