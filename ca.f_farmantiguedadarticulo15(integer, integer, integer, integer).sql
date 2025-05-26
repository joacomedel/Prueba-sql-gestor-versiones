CREATE OR REPLACE FUNCTION ca.f_farmantiguedadarticulo15(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       montoantiguedad DOUBLE PRECISION;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_farm-antiguedadarticulo15(#,&, ?,@)
--Dani modifico el 30122013 paraq tmb tenga en cuenta el concepto 1145 falta injustificada
SELECT INTO elmonto SUM(cemonto*ceporcentaje) 
		FROM ( SELECT cemonto,ceporcentaje 
		FROM ca.conceptoempleado
		NATURAL JOIN ca.concepto 
		WHERE idpersona =$3 and 
		idliquidacion = $1 and  
		(idconcepto = 1028 or idconcepto=1145  or idconcepto=1046 or idconcepto=1274  or idconcepto=1127 )  ---  or idconcepto=1127 VAS 22-12-23
--Agrego Dani 27012014 para que tenga en cuenta las LAO Farmacia
/*		and idconcepto<> 1050 and
        idconcepto<> 996 and
		idconcepto<> 1085 and
		( idconceptotipo =1 or idconceptotipo =5 or idconceptotipo = 7) */
	UNION ( SELECT 0 as monto ,0 as ceporcentaje ) ) as t;


return elmonto;
END;



/*
SELECT  SUM(cemonto*ceporcentaje) as monto FROM ( SELECT cemonto,ceporcentaje FROM ca.conceptoempleado NATURAL JOIN ca.concepto WHERE idpersona =? and idliquidacion = #  and  idconcepto<>1051 and idconcepto<> 1050 and   ( idconceptotipo =1 or idconceptotipo =5 or idconceptotipo = 7) UNION ( SELECT 0 as monto ,0 as ceporcentaje ) ) as t
*/
$function$
