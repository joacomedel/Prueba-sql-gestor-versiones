CREATE OR REPLACE FUNCTION ca.f_adicionalesmonto(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE

       monto  DOUBLE PRECISION;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/



             SELECT INTO  monto CASE WHEN nullvalue (SUM(ceporcentaje * cemonto) ) then 0
                       ELSE SUM(ceporcentaje * cemonto) END
                      FROM ca.conceptoempleado
                       NATURAL JOIN ca.concepto
                      WHERE idpersona=$2 and idliquidacion =$1 and
                          ( (idconceptotipo = 1 AND idconcepto <> 4) -- No tener en cuenta el premio como un adicional
                          OR idconcepto = 15 -- suplemento fallo de caja
                          OR idconcepto = 16 -- suplemento por riesgo
                          OR idconcepto = 17 -- suplemento por mayor responsabilidad
 
                          OR  idconcepto = 1139
OR idconcepto = 1220--Ajuste Suplemento Fallo de Caja
 OR idconcepto = 1155 -- ajuste suplemento premio
 OR idconcepto = 1128 -- ajuste suplemento por mayor responsabilidad
                          OR (idconceptotipo = 7 and idconcepto <> 1133 and idconcepto <>996)
                          )
--Dani agrgego el 2018-07-03 para que no sume el aguinaldo de farmacia por pedido de Julieta E.para q no --lo sume en los adicionales q se suben a ala afip
                          AND idconcepto <> 1092--aguinaldo farmacia
                          AND idconcepto <> 1156
                          AND idconcepto <> 1046 -- Licencia vacaciones anuales
                          
                          ;--  tener en cuenta el los concepto fallo de caja

return trunc(monto::numeric,2);
END;
$function$
