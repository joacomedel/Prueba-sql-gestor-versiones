CREATE OR REPLACE FUNCTION ca.f_retcuotaalim(integer, integer, integer, integer)
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

--f_bruto(#,&, ?,@)
   SELECT  INTO elmonto SUM(ceporcentaje * cemonto)
   FROM ca.conceptoempleado
   WHERE (idconcepto = 200 or idconcepto=201 or idconcepto=202)
         and idpersona = $3   and idliquidacion = $1;
         
   elmonto = f_bruto($1,$2,$3,$4) - elmonto;
   IF nullvalue(elmonto) THEN elmonto = 0; END IF;
return elmonto;
END;

/*
SELECT SUM(cemonto*ceporcentaje) as monto  FROM ca.conceptoempleado NATURAL JOIN ca.concepto NATURAL JOIN ca.liquidacion WHERE idpersona= ? and (idconceptotipo = 5  OR idconceptotipo =7 OR idconceptotipo =2 OR  idconceptotipo = 1 OR  idconceptotipo =10 OR  idconceptotipo =12 ) and idliquidacion= #
*/
$function$
