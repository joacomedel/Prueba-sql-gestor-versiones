CREATE OR REPLACE FUNCTION ca.f_farmatitulouniversitario(integer, integer, integer)
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

--f_aguinaldo(#,&, ?,@)

SELECT INTO elmonto SUM( ceporcentaje * cemonto  )
	FROM ca.conceptoempleado NATURAL JOIN ca.concepto
        WHERE idpersona=$3 and idliquidacion =$1 and (idconcepto=1052   or idconcepto=1053  or idconcepto=1054  or idconcepto=1042);

         IF nullvalue(elmonto) THEN return 0; END IF;
    
return elmonto;
END;
$function$
