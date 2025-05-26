CREATE OR REPLACE FUNCTION ca.f_farmaportetitulo(integer, integer, integer, integer)
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

--f_farmaportetitulo(#,&, ?,@)
SELECT INTO elmonto  SUM(cemonto*ceporcentaje) 
	FROM ( SELECT cemonto,ceporcentaje 
		FROM ca.conceptoempleado  
	NATURAL JOIN ca.concepto  
		WHERE idpersona =$3 and 		
		idliquidacion=$1 and 
		(idconcepto=1052 or idconcepto=1082 or idconcepto=1053 or idconcepto=1054 or idconcepto=1100 or idconcepto=1101)
		UNION ( SELECT 0 as monto ,0 as ceporcentaje ) ) as t;

return elmonto;
END;



/*
SELECT  SUM(cemonto*ceporcentaje) as monto FROM ( SELECT cemonto,ceporcentaje FROM ca.conceptoempleado  NATURAL JOIN ca.concepto  WHERE idpersona =? and idliquidacion = # and  idliquidacion=# and (idconcepto=1052 or idconcepto=1053 or idconcepto=1054 or idconcepto=1100 or idconcepto=1101) UNION ( SELECT 0 as monto ,0 as ceporcentaje ) ) as t
*/$function$
