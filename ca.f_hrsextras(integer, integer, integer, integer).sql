CREATE OR REPLACE FUNCTION ca.f_hrsextras(integer, integer, integer, integer)
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

--f_hrsextras(#,&, ?,@)
--SELECT INTO elmonto (cemonto* ceporcentaje) as mont
select INTO elmonto sum (T.mont)
from
    (SELECT (cemonto* ceporcentaje) as mont
	FROM ca.conceptoempleado
	WHERE idpersona =$3 and
	idconcepto = 997 and
	idliquidacion=$1
    UNION SELECT 0 as mont
    )AS t
    ;

return elmonto;
END;

/*

 SELECT (cemonto* ceporcentaje)  as monto  FROM ca.conceptoempleado WHERE idpersona =? and  idconcepto = 997 and  idliquidacion=#
*/
$function$
