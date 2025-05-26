CREATE OR REPLACE FUNCTION ca.f_diaslicencia(integer, integer, integer, integer)
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
     elmonto=0;
     --f_funcion(#,&, ?,@)
   UPDATE ca.conceptoempleado set ceporcentaje =(ttotaldias.diasmensuales - dias)
   FROM (SELECT SUM(ceporcentaje) as dias ,$3 as idpersona
         FROM ca.conceptoempleado
         WHERE idpersona =$3 and idliquidacion=$1     and (idconcepto=1121 or idconcepto=1084)  ) as t
   NATURAL JOIN  ( SELECT ceporcentaje as diasmensuales,$3 as idpersona
                   FROM ca.conceptoempleado
                   WHERE idpersona =$3 and idliquidacion=$1 and idconcepto=1045   )  as ttotaldias
   WHERE ca.conceptoempleado.idpersona =$3 and idliquidacion=$1 and idconcepto=1106  ;
return elmonto;
END;
$function$
