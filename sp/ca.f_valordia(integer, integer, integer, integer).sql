CREATE OR REPLACE FUNCTION ca.f_valordia(integer, integer, integer, integer)
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
     SELECT INTO elmonto   camonto/25
     FROM ca.persona
     NATURAL JOIN ca.categoriaempleado
     NATURAL JOIN ca.categoriatipoliquidacion
     NATURAL JOIN ca.categoriatipo
     WHERE idpersona = $3
           and idliquidaciontipo=$2
           and  CURRENT_DATE >= cefechainicio
           and  (nullvalue(cefechafin) or CURRENT_DATE <=cefechafin ) and idcategoriatipo = 1;

 return elmonto;
END;
$function$
