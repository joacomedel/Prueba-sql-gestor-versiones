CREATE OR REPLACE FUNCTION ca.f_remunerativo(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
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

--f_bruto(#,&, ?,@)


SELECT INTO elmonto CASE WHEN nullvalue( SUM(cemonto*ceporcentaje)) THEN 0
       ELSE SUM(cemonto*ceporcentaje) END
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3 and
	(idconceptotipo = 5  OR idconceptotipo =7
	OR idconceptotipo =2 OR  idconceptotipo = 1 OR
	idconceptotipo =10 or idconcepto =1105
 
    )
    and idliquidacion= $1;

return elmonto;
END;

/*
SELECT SUM(cemonto*ceporcentaje) as monto  FROM ca.conceptoempleado NATURAL JOIN ca.concepto NATURAL JOIN ca.liquidacion WHERE idpersona= ? and (idconceptotipo = 5  OR idconceptotipo =7 OR idconceptotipo =2 OR  idconceptotipo = 1 OR  idconceptotipo =10 OR  idconceptotipo =12 ) and idliquidacion= #
*/
$function$
