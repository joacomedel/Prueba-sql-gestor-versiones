CREATE OR REPLACE FUNCTION ca.f_totalasignaciones(integer, integer, integer, integer)
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

     --f_funcion(#,&, ?,@)
     SELECT INTO elmonto  sum(cemonto * ceporcentaje )
     FROM ca.conceptoempleado
     NATURAL JOIN ca.concepto
     WHERE idconceptotipo =4 and  idliquidacion=$1 and idpersona=$3;

 return elmonto;
END;
$function$
