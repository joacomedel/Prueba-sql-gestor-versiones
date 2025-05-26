CREATE OR REPLACE FUNCTION ca.f_farmadicionalvolunario(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE

        montototal DOUBLE PRECISION;
        rliquidacion record;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_farmaguinaldo(#,&, ?,@)


SELECT INTO rliquidacion *
	FROM ( SELECT SUM(ceporcentaje * cemonto)as monto,idliquidacion
		   FROM ca.conceptoempleado
	       NATURAL JOIN ca.liquidacion
		   WHERE idpersona=$3 and 	idliquidaciontipo=2 and
		      (idconcepto=1028 or idconcepto=1050 or idconcepto=1048
               or idconcepto =1133  or idconcepto=996 or idconcepto =1085
               or idconcepto =1142
               or idconcepto=1159 or idconcepto =1156
               or idconcepto=1157 or idconcepto=1080
               or idconcepto=1151 or idconcepto=1152
               or idconcepto=1158 or idconcepto=1046
                or idconcepto=1145
                or idconcepto=1192
                or idconcepto=1181 or idconcepto=1182
               or idconcepto=1207
            )  	
          group by idliquidacion
          ORDER by idliquidacion DESC
          limit 6
          ) as T
     ORDER BY monto DESC
     LIMIT 1;

     SELECT INTO montototal (ceporcentaje * cemonto) FROM ca.conceptoempleado
     WHERE idliquidacion =rliquidacion.idliquidacion and idpersona = $3 and idconcepto=1135;

   if not found then 
        montototal=0;
   end if;

return montototal ;
END;



/*
SELECT ((MAX(monto)/6) * count(*)) as monto  FROM ( SELECT SUM(ceporcentaje * cemonto)as monto,idliquidacion FROM ca.conceptoempleado NATURAL JOIN ca.liquidacion WHERE idpersona=? and (idconcepto=1028 or idconcepto=1050 or idconcepto=1048) and  idliquidaciontipo=2 group by idliquidacion  ORDER by idliquidacion DESC  ) as T
*/
$function$
