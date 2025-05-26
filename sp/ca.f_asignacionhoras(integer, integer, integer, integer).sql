CREATE OR REPLACE FUNCTION ca.f_asignacionhoras(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       porphoras DOUBLE PRECISION;
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

   SELECT INTO porphoras  case when (cemonto<>0 and ceporcentaje<>0) then round ((cemonto/ceporcentaje)::numeric,7)
         else 0 end as valor FROM ca.conceptoempleado
          WHERE idpersona =$3 and idliquidacion=$1 and idconcepto=100;
/* VSA 171220            
    UPDATE ca.conceptoempleado set ceporcentaje = porphoras
    WHERE  idpersona =$3 and idliquidacion=$1
           and ( idconcepto = 0  or idconcepto = 1211
                 -- or idconcepto =  concepto que sean proporcional a las horas trabajadas
                 );
*/
    UPDATE ca.conceptoempleado set cemonto =porphoras
    WHERE  idpersona =$3 and idliquidacion=$1 
            and ( idconcepto=998 or idconcepto=1106 
                 -- or idconcepto =  concepto que sean proporcional a las horas trabajadas
                );



return elmonto;
END;
$function$
