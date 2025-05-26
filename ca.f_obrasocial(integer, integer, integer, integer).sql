CREATE OR REPLACE FUNCTION ca.f_obrasocial(integer, integer, integer, integer)
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

     --f_funcion(#,&, ?,@)
     SELECT INTO elmonto SUM(cemonto*ceporcentaje)
     FROM ca.conceptoempleado
     NATURAL JOIN ca.concepto
     NATURAL JOIN ca.liquidacion
     WHERE idpersona= $3
           and (idconceptotipo = 1 OR idconceptotipo =7 OR idconceptotipo =2 OR  idconceptotipo = 5   OR  idconceptotipo =10 ) and idconcepto<>1232
           and idliquidacion= $1;


 return 	elmonto;
END;
$function$
