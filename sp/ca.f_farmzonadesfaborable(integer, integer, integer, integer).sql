CREATE OR REPLACE FUNCTION ca.f_farmzonadesfaborable(integer, integer, integer, integer)
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

--f_farmaguinaldo(#,&, ?,@)


SELECT INTO elmonto   SUM(cemonto*ceporcentaje)
FROM ( SELECT cemonto,ceporcentaje
       FROM ca.conceptoempleado
       NATURAL JOIN ca.concepto
       WHERE idpersona =$3 and idliquidacion = $1
             and idconcepto<>1051
           --  and idconcepto=1274
             and idconcepto<>1156
             and idconcepto<>1157
--Dani modifico el 18-11-16 para  q deje afuera el 1070
             and idconcepto<>1070
             and idconcepto<>1158
             and idconcepto<> 996  ---- 26-02-2015 saco las horas extras
             and idconcepto<> 1228 -- 01/08/18 (09:56:54) Julieta Esteves (int. 50): osea que para el calculo de zona 1156 no sume el 1228 
 and idconcepto<> 1104
 and idconcepto<> 1282 --- 2906 se quito el concepto xq no hay que tenerlo en cuenta
             and ( idconceptotipo =1 or idconceptotipo =5 or idconceptotipo = 7 )
            
UNION ( SELECT 0 as monto ,0 as ceporcentaje ) ) as t;

return elmonto;
END;
$function$
