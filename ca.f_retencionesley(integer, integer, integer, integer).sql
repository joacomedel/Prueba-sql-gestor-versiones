CREATE OR REPLACE FUNCTION ca.f_retencionesley(integer, integer, integer, integer)
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

--f_bruto(#,&, ?,@)


SELECT INTO elmonto CASE WHEN nullvalue( SUM(cemonto*ceporcentaje)) THEN 0
       ELSE SUM(cemonto*ceporcentaje) END
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3 and
	(idconcepto =200  --Jubilacion
    or idconcepto=201  -- Ley 19032
    or idconcepto=202)  -- SOSUNC
    and idliquidacion= $1;

return elmonto;
END;
$function$
