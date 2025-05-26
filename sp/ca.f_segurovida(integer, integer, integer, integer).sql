CREATE OR REPLACE FUNCTION ca.f_segurovida(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE


        monto DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_aguinaldo(#,&, ?,@)


    SELECT  INTO monto SUM(t.cemonto)
    FROM (
        SELECT cemonto
        FROM ca.conceptoempleado
        NATURAL JOIN ca.concepto
        WHERE idpersona =$3 and idliquidacion =$1 and idconcepto=987
        UNION SELECT 0 as cemonto
    )as t;

return monto;

END;



/*
 SELECT ((MAX(montomax)/6) * count(*)) as monto FROM (  SELECT (leimpbruto - (Case WHEN nullvalue(cemonto) THEN 0 ELSE cemonto END)) as montomax FROM (SELECT idliquidacion,leimpbruto  FROM ca.liquidacionempleado NATURAL JOIN ca.liquidacion WHERE idpersona=? and ( idliquidaciontipo =1 OR idliquidaciontipo=2) and lianio = extract(YEAR from CURRENT_DATE) order by lianio DESC, limes DESC   limit 6 ) AS B LEFT  JOIN   ( SELECT idliquidacion,  SUM(cemonto*ceporcentaje )as cemonto   FROM ca.liquidacionempleado NATURAL JOIN ca.liquidacion NATURAL JOIN ca.conceptoempleado WHERE idpersona=? and ( idliquidaciontipo =1 OR idliquidaciontipo=2) and lianio = extract(YEAR from CURRENT_DATE) and (idconcepto =4 or idconcepto = 33)  GROUP by idliquidacion,lianio, limes   order by lianio DESC, limes DESC   limit 6  )as P USING (idliquidacion)  ) as T
*/
$function$
