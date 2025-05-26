CREATE OR REPLACE FUNCTION ca.f_embargojudicial(integer, integer, integer, integer)
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





         SELECT INTO elmonto   SUM(cemonto*ceporcentaje)
         FROM ca.conceptoempleado
         NATURAL JOIN ca.concepto
         WHERE idpersona =$3
               -- AND (idliquidacion =320 OR idliquidacion =322 )
               AND idliquidacion = $1
               AND idconceptotipo <> 3 -- 3	Retenciones
               AND idconceptotipo <> 4 -- Asignaciones Familiares
               AND idconceptotipo <> 8 -- Deduccion extraordinaria	
               AND idconceptotipo <> 11 -- Variables Globales
           
              AND idconcepto <> 1105
          
           
       ;

return elmonto;
END;


$function$
