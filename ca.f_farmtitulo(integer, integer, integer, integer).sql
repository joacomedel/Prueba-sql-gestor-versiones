CREATE OR REPLACE FUNCTION ca.f_farmtitulo(integer, integer, integer, integer)
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

--f_farmhaberes(#,&, ?,@)
--Dani modifico 30122013 para q tenga en cuenta tmb el caso de q la persona 
--tenga el concepto 1145 falta injustificada
SELECT INTO  elmonto case  when  nullvalue(SUM(cemonto*ceporcentaje)) then 0 else SUM(cemonto*ceporcentaje)end  as valor 
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3 and
	      (idconcepto = 1028 OR idconcepto =1050  OR idconcepto =1145   OR idconcepto =1046 or idconcepto=1127) and  ---  or idconcepto=1127 VAS 22-12-23
--Agrego Dani 27012014 para q tenga en cuenta LAO farmacia
	idliquidacion= $1;
return 	elmonto;
END;

/*
SELECT SUM(cemonto*ceporcentaje) as monto FROM ca.conceptoempleado NATURAL JOIN ca.concepto NATURAL JOIN ca.liquidacion WHERE idpersona= ? and (idconceptotipo = 1 OR idconceptotipo =7 OR idconceptotipo =2 OR  idconceptotipo = 5 OR  idconceptotipo =10 ) and idliquidacion= #

*/
$function$
