CREATE OR REPLACE FUNCTION ca.f_basicocategoria(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_basicocategoria(#,&, ?,@)
/*28-10-19 Dani modifico el redondeo de 3 a 5 decimales */
SELECT INTO elmonto round ((montobasico/(CASE WHEN diasmes=0 THEN 30 ELSE  diasmes END))::numeric,5)
		FROM ( SELECT SUM(montobasico)as  montobasico , SUM(diasmes)as diasmes
		FROM ( SELECT camonto  as montobasico,0 as diasmes
		        FROM ca.persona
		        NATURAL JOIN ca.categoriaempleado
		        NATURAL JOIN ca.categoriatipoliquidacion
		        NATURAL JOIN ca.categoriatipo
                        NATURAL JOIN ca.conceptoempleado
                        NATURAL JOIN ca.liquidacion
		        WHERE idpersona = $3 and
		        idliquidaciontipo=$2  and
                        idliquidacion=$1 and 
		        CURRENT_DATE >= cefechainicio and idcategoria<>21 and 
	         	(nullvalue(cefechafin) or /*CURRENT_DATE <=cefechafin */ (date_trunc('month', concat(lianio,'-',limes,'-1')::date) <= cefechafin)) and
		      idcategoriatipo = 1
	UNION  SELECT 0 as montobasico, ceporcentaje as diasmes
		FROM ca.conceptoempleado
		WHERE idpersona =$3 and
		idliquidacion=$1   and
		idconcepto=1045   --dias laborables mensuales
    --se agrega por pedido de JE y aprobacion de MC segun mail 22032022 
    --se comenta por pedido por telefonode JE no debe formar parte del basico sino solo sumarse en los adicionales         
       /*UNION  SELECT cemonto as montobasico, 0 as diasmes
		FROM ca.conceptoempleado
		WHERE idpersona =$3 and
		idliquidacion=$1   and
		idconcepto=1139 */--ajuste basico
 ) as D )as T;  -- dias correspondientes basico

return 	elmonto;
END;

/*
SELECT round ((montobasico/diasmes* diasbasico)::numeric,3) as monto FROM ( SELECT SUM(montobasico)as  montobasico , SUM(diasmes)as diasmes,SUM(diasbasico)as diasbasico FROM ( SELECT camonto  as montobasico,0 as diasmes,0 as diasbasico FROM ca.persona NATURAL JOIN ca.categoriaempleado NATURAL JOIN ca.categoriatipoliquidacion NATURAL JOIN ca.categoriatipo  WHERE idpersona = ? and idliquidaciontipo=1  and  CURRENT_DATE >= cefechainicio and (nullvalue(cefechafin) or CURRENT_DATE <=cefechafin ) and idcategoriatipo = 1 UNION  SELECT 0 as montobasico, ceporcentaje as diasmes,0 as diasbasico    FROM ca.conceptoempleado WHERE idpersona =? and idliquidacion=#   and idconcepto=1045 UNION SELECT  0 as montobasico, 0 as diasmes , ceporcentaje as diasbasico FROM ca.conceptoempleado WHERE idpersona =? and idliquidacion=#   and idconcepto=1084 ) as D )as T
*/
$function$
