CREATE OR REPLACE FUNCTION ca.f_deducciones(integer, integer, integer, integer)
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

--f_deducciones(#,&, ?,@)


SELECT INTO elmonto SUM(cemonto*ceporcentaje)
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3 and
	(idconceptotipo = 8 OR idconceptotipo =3) and
	idliquidacion= $1;

return elmonto;
END;

/*
SELECT SUM(cemonto*ceporcentaje) as monto FROM ca.conceptoempleado NATURAL JOIN ca.concepto NATURAL JOIN ca.liquidacion WHERE idpersona= ? and (idconceptotipo = 8 OR idconceptotipo =3) and idliquidacion= #

*/
$function$
