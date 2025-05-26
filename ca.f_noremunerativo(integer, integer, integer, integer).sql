CREATE OR REPLACE FUNCTION ca.f_noremunerativo(integer, integer, integer, integer)
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
    WHERE idpersona=$3 and idliquidacion =$1 and (idconceptotipo=12 or idconceptotipo=4);
    
return elmonto;
END;
$function$
